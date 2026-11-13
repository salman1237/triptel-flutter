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
import '../../catalog/application/plan_shape.dart';
import '../../catalog/data/models/product.dart';
import '../application/checkout_breakdown.dart';
import '../application/discounts_providers.dart';
import '../data/models/discount_check_result.dart';

/// Arguments for `/checkout/review` -- go_router's `extra`, since a [Product]
/// isn't URL-encodable (Architecture.md's routing table has no query params
/// for this route).
class CheckoutReviewArgs {
  const CheckoutReviewArgs({required this.product, required this.countryName});

  final Product product;
  final String countryName;
}

/// FR-302/FR-303: checkout review screen (Design_System.md §57). Plan
/// header, voucher row (opens code entry, wired to FR-303's real
/// `POST /discounts/check` guest estimate -- a scoped code says "exact
/// savings confirmed when you sign in" rather than applying silently), a
/// reward-credit toggle row (display-only per Design_System.md's own note:
/// the backend decides whether REWARD balance is spent, not the user), a
/// price breakdown card, and a sticky bottom bar with "Continue to payment"
/// (FR-305+ doesn't exist yet).
class CheckoutReviewScreen extends ConsumerStatefulWidget {
  const CheckoutReviewScreen({super.key, required this.args});

  final CheckoutReviewArgs args;

  @override
  ConsumerState<CheckoutReviewScreen> createState() =>
      _CheckoutReviewScreenState();
}

class _CheckoutReviewScreenState extends ConsumerState<CheckoutReviewScreen> {
  DiscountCheckResult? _discount;

  void _showComingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.args.product;
    final rateAsync = ref.watch(selectedCurrencyRateProvider);
    final currencyAsync = ref.watch(currencyPreferenceProvider);

    final discount = _discount;
    final breakdown = CheckoutBreakdown(
      subtotal: product.retailPrice,
      discount: discount != null
          ? estimateDiscount(discount, product.retailPrice)
          : const Money(0),
    );

    String money(Money amount) => switch ((rateAsync, currencyAsync)) {
          (AsyncData(value: final rate), AsyncData(value: final code)) =>
            formatMoney(amount, currencyCode: code, rateToBase: rate),
          _ => '',
        };

    return Scaffold(
      key: const ValueKey('checkout-review-screen'),
      backgroundColor: AppColors.lilac50,
      appBar: AppBar(
        backgroundColor: AppColors.lilac50,
        elevation: 0,
        title: const Text('Checkout'),
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
                      '${planDataLabel(product)} · ${product.validityDays} '
                      'days · ${planCoverageLabel(product)}',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 20),
                    ListGroup(
                      children: [
                        ListRow(
                          key: const ValueKey('voucher-row'),
                          icon: Icons.local_offer_outlined,
                          title: discount != null && discount.valid
                              ? 'Voucher applied'
                              : 'Add a voucher code',
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
                          text: 'Exact savings confirmed when you sign in.',
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
                            child: Text('Use reward credit',
                                style: AppTypography.body()),
                          ),
                          Switch(
                            key: const ValueKey('reward-credit-toggle'),
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
                            label: 'Subtotal',
                            value: money(breakdown.subtotal),
                          ),
                          if (breakdown.hasDiscount)
                            _BreakdownRow(
                              key: const ValueKey('discount-row'),
                              label: 'Voucher',
                              value: '- ${money(breakdown.discount)}',
                              valueColor: AppColors.success,
                            ),
                          const Divider(height: 24, color: AppColors.line),
                          _BreakdownRow(
                            label: 'Total',
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
              ctaLabel: 'Continue to payment',
              onPressed: () => _showComingSoon(context, 'Payment'),
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
          _errorText = result.reason ?? "That code isn't valid.";
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
          Text('Voucher code', style: AppTypography.headline()),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('voucher-code-field'),
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter code',
              filled: true,
              fillColor: AppColors.surface,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey('voucher-apply-button'),
            label: _checking ? 'Checking…' : 'Apply',
            onPressed: _checking ? null : _apply,
          ),
        ],
      ),
    );
  }
}
