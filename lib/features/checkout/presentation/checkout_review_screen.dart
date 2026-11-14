import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../catalog/application/plan_shape.dart';
import '../../catalog/data/models/product.dart';
import '../../wallet/application/wallet_balance.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/data/models/wallet.dart';
import '../application/checkout_breakdown.dart';
import '../application/discounts_providers.dart';
import '../application/order_status_launcher.dart';
import '../application/orders_providers.dart';
import '../application/shurjopay_launcher.dart';
import '../data/models/discount_check_result.dart';
import '../data/models/order.dart';
import '../data/models/shurjopay_checkout.dart';
import 'purchase_success_screen.dart';

/// Arguments for `/checkout/review` -- go_router's `extra`, since a [Product]
/// isn't URL-encodable (Architecture.md's routing table has no query params
/// for this route).
class CheckoutReviewArgs {
  const CheckoutReviewArgs({required this.product, required this.countryName});

  final Product product;
  final String countryName;
}

/// FR-302/FR-303/FR-304: checkout review screen (Design_System.md §57).
/// Plan header, voucher row (opens code entry, wired to FR-303's real
/// `POST /discounts/check` guest estimate -- a scoped code says "exact
/// savings confirmed when you sign in" rather than applying silently), a
/// reward-credit toggle row (display-only per Design_System.md's own note:
/// the backend decides whether REWARD balance is spent, not the user), a
/// price breakdown card, and a sticky bottom bar with "Continue to payment"
/// (FR-305+ doesn't exist yet) which runs FR-304's authoritative
/// `/discounts/preview` re-check first when a discount is applied and the
/// user is signed in.
class CheckoutReviewScreen extends ConsumerStatefulWidget {
  const CheckoutReviewScreen({super.key, required this.args});

  final CheckoutReviewArgs args;

  @override
  ConsumerState<CheckoutReviewScreen> createState() =>
      _CheckoutReviewScreenState();
}

class _CheckoutReviewScreenState extends ConsumerState<CheckoutReviewScreen> {
  DiscountCheckResult? _discount;
  bool _confirmingDiscount = false;
  bool _placingOrder = false;

  CheckoutBreakdown get _breakdown {
    final discount = _discount;
    final subtotal = widget.args.product.retailPrice;
    return CheckoutBreakdown(
      subtotal: subtotal,
      discount: discount != null
          ? estimateDiscount(discount, subtotal)
          : const Money(0),
    );
  }

  String _formatMoney(Money amount) {
    final rate = ref.read(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.read(currencyPreferenceProvider).valueOrNull;
    if (rate == null || code == null) return '';
    return formatMoney(amount, currencyCode: code, rateToBase: rate);
  }

  /// Safely resolves the current auth state. `authNotifierProvider.future`
  /// rethrows if `AuthNotifier.build()` itself errored (e.g. a transient
  /// network failure refreshing the session) -- an uncaught throw here
  /// would silently abort the whole continue-to-payment action with no
  /// feedback to the user. Treat a resolution failure the same as a
  /// guest: safe (every downstream branch already handles "not
  /// authenticated"), and never worse than what a real guest already
  /// gets.
  Future<AuthState> _resolveAuthState() async {
    try {
      return await ref.read(authNotifierProvider.future);
    } catch (_) {
      return const AuthUnauthenticated();
    }
  }

  /// FR-304: before charging (the one real "about to pay" trigger that
  /// exists today, since FR-306/307's real purchase flows don't),
  /// authoritatively re-confirm an applied discount via
  /// `POST /discounts/preview` -- codes can expire or become invalid
  /// between FR-303's guest estimate and now. Invalid -> show the reason
  /// and keep the user on review (never proceeds). Skipped for a guest:
  /// the endpoint requires auth, and there's no sign-in-and-resume flow
  /// yet (FR-106, deferred). Resolves auth via [_resolveAuthState] rather
  /// than reading `ref.read(authNotifierProvider).valueOrNull` directly --
  /// the latter returned null/AsyncLoading on first access here since
  /// nothing else in this screen watches the provider, so its
  /// AsyncNotifier.build() hadn't resolved yet. Once the discount (if any)
  /// is confirmed, FR-305's payment method choice runs next.
  Future<void> _onContinueToPayment() async {
    final discount = _discount;
    if (discount == null || !discount.valid || discount.code == null) {
      await _choosePaymentMethod();
      return;
    }
    final authState = await _resolveAuthState();
    if (!mounted) return;
    if (authState is! AuthAuthenticated) {
      await _choosePaymentMethod();
      return;
    }

    setState(() => _confirmingDiscount = true);
    try {
      final preview = await ref
          .read(discountsApiProvider)
          .preview(discount.code!, widget.args.product.id);
      if (!mounted) return;
      if (!preview.valid) {
        setState(() {
          _discount = null;
          _confirmingDiscount = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(preview.reason ?? "That code is no longer valid.")));
        return;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _confirmingDiscount = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _confirmingDiscount = false);
    await _choosePaymentMethod();
  }

  /// FR-305: Wallet is offered as a payment method only when
  /// DEFAULT+REWARD fully covers the total; otherwise skip the sheet and
  /// go straight to FR-307's real ShurjoPay checkout. A guest has no
  /// wallet, so always goes straight to ShurjoPay too. Selecting Wallet
  /// runs FR-306's real checkout instead.
  Future<void> _choosePaymentMethod() async {
    final authState = await _resolveAuthState();
    if (!mounted) return;

    var wallets = const <Wallet>[];
    if (authState is AuthAuthenticated) {
      try {
        wallets = await ref.read(walletsApiProvider).getMyWallets();
      } on ApiException {
        wallets = const [];
      }
      if (!mounted) return;
    }

    final total = _breakdown.total;
    if (walletCoversTotal(wallets, total)) {
      final spendable = spendableBalance(wallets);
      final after = spendable - total;
      final selected = await PaymentMethodSheet.show(context, [
        PaymentMethodOption(
          id: 'wallet',
          label: 'Wallet',
          subtitle:
              'Balance ${_formatMoney(spendable)} · After: ${_formatMoney(after)}',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const PaymentMethodOption(
          id: 'shurjopay',
          label: 'ShurjoPay',
          icon: Icons.credit_card,
        ),
      ]);
      if (!mounted || selected == null) return;
      if (selected == 'wallet') {
        await _checkoutWithWallet();
        return;
      }
    }
    await _checkoutWithShurjoPay();
  }

  /// FR-309: anything other than `COMPLETED`/`FAILED` once the poll window
  /// (API.md section 6, ~170s) runs out is "still preparing", never an
  /// error (Rules.md) -- the backend keeps provisioning in the background
  /// and emails the eSIM when ready.
  /// FR-310: a completed order goes to the real purchase-success screen
  /// (QR, 1-tap install, copy code, "Go to My eSIMs") instead of a snack.
  void _showOrderResult(Order order) {
    if (order.isCompleted) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(order: order)));
      return;
    }
    final message = order.isFailed
        ? 'Order ${order.orderNo}: failed -- refunded to your wallet.'
        : "We're still setting up your eSIM -- it will appear in My "
            'eSIMs and arrive by email.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// FR-306: `POST /orders/checkout` (wallet only) then poll
  /// `GET /orders/{id}` until `COMPLETED`/`FAILED` or the schedule runs
  /// out -- anything else, including a timeout, is "still processing",
  /// never a failure (Rules.md, API.md §6).
  Future<void> _checkoutWithWallet() async {
    final discount = _discount;
    setState(() => _placingOrder = true);
    try {
      final api = ref.read(ordersApiProvider);
      final order = await api.checkout(
        productId: widget.args.product.id,
        discountCode: discount != null && discount.valid ? discount.code : null,
      );
      if (!mounted) return;
      final launchStatus = ref.read(orderStatusLauncherProvider);
      final finalOrder = await launchStatus(context, api, order.id);
      if (!mounted) return;
      setState(() => _placingOrder = false);
      _showOrderResult(finalOrder);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// FR-307: `POST /payments/shurjopay/order-initiate` (mobile: true), open
  /// the real `checkout_url` in an in-app WebView, and wait for it to pop
  /// with the parsed terminal redirect. The redirect is a hint, not proof
  /// (API.md §9) -- either way, once the WebView closes with a redirect,
  /// re-poll the real order via FR-306's `pollOrderUntilDone`. Backing out
  /// of the WebView without a terminal redirect (`callback == null`) just
  /// returns to review with no order to poll.
  Future<void> _checkoutWithShurjoPay() async {
    final discount = _discount;
    setState(() => _placingOrder = true);
    ShurjoPayCheckout checkout;
    try {
      checkout = await ref.read(ordersApiProvider).initiateShurjoPay(
            productId: widget.args.product.id,
            discountCode:
                discount != null && discount.valid ? discount.code : null,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _placingOrder = false);

    final launch = ref.read(shurjoPayLauncherProvider);
    final callback = await launch(context, checkout.checkoutUrl);
    if (!mounted || callback == null) return;

    setState(() => _placingOrder = true);
    try {
      final api = ref.read(ordersApiProvider);
      final launchStatus = ref.read(orderStatusLauncherProvider);
      final finalOrder = await launchStatus(context, api, checkout.orderId);
      if (!mounted) return;
      setState(() => _placingOrder = false);
      _showOrderResult(finalOrder);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.args.product;
    final rateAsync = ref.watch(selectedCurrencyRateProvider);
    final currencyAsync = ref.watch(currencyPreferenceProvider);

    final discount = _discount;
    final breakdown = _breakdown;

    String money(Money amount) => switch ((rateAsync, currencyAsync)) {
          (AsyncData(value: final rate), AsyncData(value: final code)) =>
            formatMoney(amount, currencyCode: code, rateToBase: rate),
          _ => "",
        };

    return Scaffold(
      key: const ValueKey("checkout-review-screen"),
      backgroundColor: AppColors.lilac50,
      appBar: AppBar(
        backgroundColor: AppColors.lilac50,
        elevation: 0,
        title: const Text("Checkout"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.gutter),
            child: CurrencyPillSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      product.titleEn,
                      textAlign: TextAlign.center,
                      style: AppTypography.headline(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${planDataLabel(product)} · ${product.validityDays} "
                      "days · ${planCoverageLabel(product)}",
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 20),
                    ListGroup(
                      children: [
                        ListRow(
                          key: const ValueKey("voucher-row"),
                          icon: Icons.local_offer_outlined,
                          title: discount != null && discount.valid
                              ? "Voucher applied"
                              : "Add a voucher code",
                          subtitle: discount != null && discount.valid
                              ? discount.code
                              : null,
                          onTap: () => _showVoucherSheet(context),
                        ),
                      ],
                    ),
                    if (discount != null && discount.valid && discount.scoped)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InfoBox(
                          text: "Exact savings confirmed when you sign in.",
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: const [appCardShadow],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text("Use reward credit",
                                style: AppTypography.body()),
                          ),
                          Switch(
                            key: const ValueKey("reward-credit-toggle"),
                            value: false,
                            onChanged: null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: const [appCardShadow],
                      ),
                      child: Column(
                        children: [
                          _BreakdownRow(
                            label: "Subtotal",
                            value: money(breakdown.subtotal),
                          ),
                          if (breakdown.hasDiscount)
                            _BreakdownRow(
                              key: const ValueKey("discount-row"),
                              label: "Voucher",
                              value: "- ${money(breakdown.discount)}",
                              valueColor: AppColors.success,
                            ),
                          const Divider(height: 24, color: AppColors.line),
                          _BreakdownRow(
                            label: "Total",
                            value: money(breakdown.total),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StickyTotalBar(
              totalText: money(breakdown.total),
              savingsText: breakdown.hasDiscount
                  ? "You've saved ${money(breakdown.discount)}"
                  : null,
              ctaLabel: _confirmingDiscount
                  ? "Checking…"
                  : _placingOrder
                      ? "Placing order…"
                      : "Continue to payment",
              onPressed: _confirmingDiscount || _placingOrder
                  ? null
                  : _onContinueToPayment,
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoucherSheet(
        onApplied: (result) {
          Navigator.of(context).maybePop();
          setState(() => _discount = result);
        },
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTypography.body().copyWith(fontWeight: FontWeight.bold)
        : AppTypography.body(color: AppColors.inkMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _VoucherSheet extends ConsumerStatefulWidget {
  const _VoucherSheet({required this.onApplied});

  final ValueChanged<DiscountCheckResult> onApplied;

  @override
  ConsumerState<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends ConsumerState<_VoucherSheet> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _checking = true;
      _errorText = null;
    });
    try {
      final result = await ref.read(discountsApiProvider).check(code);
      if (!mounted) return;
      if (result.valid) {
        widget.onApplied(result);
      } else {
        setState(() {
          _checking = false;
          _errorText = result.reason ?? "That code is not valid.";
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _errorText = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 20, AppSpacing.gutter,
          20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.lilac50,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Voucher code", style: AppTypography.headline()),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey("voucher-code-field"),
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter code",
              filled: true,
              fillColor: AppColors.surface,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey("voucher-apply-button"),
            label: _checking ? "Checking…" : "Apply",
            onPressed: _checking ? null : _apply,
          ),
        ],
      ),
    );
  }
}
