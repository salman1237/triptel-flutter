import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/install/install_link.dart';
import '../../../core/install/url_launcher_provider.dart';
import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/application/esim_verdict.dart';
import '../../wallet/application/wallet_balance.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/data/models/wallet.dart';
import '../application/esim_history_shape.dart';
import '../application/esim_install_links.dart';
import '../application/esim_lifecycle_shape.dart';
import '../application/esim_status_providers.dart';
import '../application/esim_usage_shape.dart';
import '../application/topup_launcher.dart';
import '../data/models/esim_status.dart';
import '../data/models/topup_option.dart';
import '../data/models/topup_shurjopay_checkout.dart';
import '../../support/presentation/report_problem_screen.dart';

/// FR-403: eSIM detail -- usage. `GET /esims/{id}/status`: usage ring/bar
/// (allowance incl. top-ups; none for unlimited), remaining, validity
/// countdown or "starts on install", status label, telemetry-stale banner,
/// manual refresh (`POST /refresh`, 30s client-side cooldown).
/// FR-404: install section -- QR reveal, 1-tap install (gated by FR-950's
/// verdict, per Rules.md's compatibility rule: detection only ever gates
/// the 1-tap button, never the QR/manual codes, which stay useful for
/// installing on a different device), manual SM-DP+/matching ID/LPA copy,
/// an "install only once" warning, and a link to the web setup guide
/// (FR-901 isn't ported into the app yet). FR-405: a lifecycle banner for
/// SUSPENDED/REVOKED/CANCELLED/EXPIRED replaces the entire install section.
/// FR-406: history/daily breakdown, VivaPe-only, shown only when present.
/// FR-407: top-up options (`GET /esims/{id}/topup-options`), hidden
/// entirely when empty (non-eSIM-Access profile, or not yet delivered) --
/// purchasing a package (FR-408) isn't built yet, so tapping one shows a
/// "coming soon" note instead of a dead end.
class EsimDetailScreen extends ConsumerStatefulWidget {
  const EsimDetailScreen({super.key, required this.esimId});

  final String esimId;

  @override
  ConsumerState<EsimDetailScreen> createState() => _EsimDetailScreenState();
}

class _EsimDetailScreenState extends ConsumerState<EsimDetailScreen> {
  EsimStatus? _override;
  DateTime? _lastRefreshedAt;
  bool _refreshing = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _scheduleCooldownRefresh() {
    _cooldownTimer?.cancel();
    final remaining =
        refreshCooldownRemaining(_lastRefreshedAt, DateTime.now());
    if (remaining > Duration.zero) {
      _cooldownTimer = Timer(remaining, () {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    try {
      final fresh =
          await ref.read(esimStatusApiProvider).refresh(widget.esimId);
      if (!mounted) return;
      setState(() {
        _override = fresh;
        _lastRefreshedAt = DateTime.now();
      });
      _scheduleCooldownRefresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  Future<void> _install(String url) async {
    final launch = ref.read(urlLauncherProvider);
    final opened = await launch(Uri.parse(url));
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the install link.")));
    }
  }

  Future<void> _openSetupGuide() async {
    final launch = ref.read(urlLauncherProvider);
    final opened = await launch(Uri.parse(setupGuideUrl()));
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the setup guide.")));
    }
  }

  void _onReportProblem(EsimStatus status) {
    context.push('/my-esims/${widget.esimId}/report-problem',
        extra: ReportProblemArgs(
          esimId: widget.esimId,
          orderNo: status.orderNo,
          planTitle: status.product.title,
        ));
  }

  String _formatMoney(Money amount) {
    final rate = ref.read(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.read(currencyPreferenceProvider).valueOrNull;
    if (rate == null || code == null) return '';
    return formatMoney(amount, currencyCode: code, rateToBase: rate);
  }

  /// FR-408: same payment-method choice as FR-305's first purchase --
  /// wallet offered only when DEFAULT+REWARD covers the price, else go
  /// straight to ShurjoPay.
  Future<void> _onTopupOptionTap(TopupOption option) async {
    var wallets = const <Wallet>[];
    try {
      wallets = await ref.read(walletsApiProvider).getMyWallets();
    } on ApiException {
      wallets = const [];
    }
    if (!mounted) return;

    if (walletCoversTotal(wallets, option.retailPrice)) {
      final spendable = spendableBalance(wallets);
      final after = spendable - option.retailPrice;
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
        await _topupWithWallet(option);
        return;
      }
    }
    await _topupWithShurjoPay(option);
  }

  Future<void> _topupWithWallet(TopupOption option) async {
    try {
      final result = await ref
          .read(esimStatusApiProvider)
          .topupWithWallet(widget.esimId, option.packageCode);
      if (!mounted) return;
      ref.invalidate(esimStatusProvider(widget.esimId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.failed
              ? 'Top-up failed -- refunded to your wallet.'
              : 'Top-up successful.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// `POST /payments/shurjopay/esim-topup-initiate` is `(auth,
  /// password-changed)` (API.md section 7) -- a real 403 here routes to
  /// Set Password, same as FR-105b's checkout guard.
  Future<void> _topupWithShurjoPay(TopupOption option) async {
    TopupShurjoPayCheckout checkout;
    try {
      checkout = await ref
          .read(esimStatusApiProvider)
          .initiateTopupShurjoPay(widget.esimId, option.packageCode);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.mustChangePassword) {
        context.push('/set-password');
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;

    final launch = ref.read(topupLauncherProvider);
    final failed = await launch(context, checkout.checkoutUrl, widget.esimId);
    if (!mounted || failed == null) return;

    ref.invalidate(esimStatusProvider(widget.esimId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failed ? 'Top-up failed.' : 'Top-up successful.')));
  }

  /// FR-409: share the real web tracking link -- null on the (unused here)
  /// public status variant, so the action is simply absent rather than a
  /// dead tap (checked by the caller before building the AppBar action).
  Future<void> _shareTrackingLink(String shareUrl) async {
    await SharePlus.instance.share(ShareParams(text: shareUrl));
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(esimStatusProvider(widget.esimId));
    final verdictAsync = ref.watch(esimVerdictProvider);
    final topupOptions =
        ref.watch(topupOptionsProvider(widget.esimId)).valueOrNull ??
            const <TopupOption>[];
    final shareUrl = statusAsync.valueOrNull?.shareUrl;

    return TriptelScaffold(
      key: const ValueKey('esim-detail-screen'),
      appBar: AppBar(
        title: const Text('eSIM details'),
        actions: [
          if (shareUrl != null)
            IconButton(
              key: const ValueKey('esim-share-tracking-link'),
              icon: const Icon(Icons.share),
              onPressed: () => _shareTrackingLink(shareUrl),
            ),
          IconButton(
            key: const ValueKey('esim-view-receipt'),
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/my-esims/${widget.esimId}/print'),
          ),
        ],
      ),
      body: switch (statusAsync) {
        AsyncData(:final value) => _Body(
            status: _override ?? value,
            refreshing: _refreshing,
            cooldownRemaining:
                refreshCooldownRemaining(_lastRefreshedAt, DateTime.now()),
            onRefresh: _onRefresh,
            verdict: verdictAsync.valueOrNull ??
                const EsimVerdict(
                    kind: EsimVerdictKind.unknown, deviceLabel: '', reason: ''),
            onInstall: _install,
            onCopy: _copy,
            onOpenSetupGuide: _openSetupGuide,
            topupOptions: topupOptions,
            onTopupOptionTap: _onTopupOptionTap,
            onReportProblem: () => _onReportProblem(_override ?? value),
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load this eSIM.",
              onRetry: () => ref.invalidate(esimStatusProvider(widget.esimId)),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.status,
    required this.refreshing,
    required this.cooldownRemaining,
    required this.onRefresh,
    required this.verdict,
    required this.onInstall,
    required this.onCopy,
    required this.onOpenSetupGuide,
    required this.topupOptions,
    required this.onTopupOptionTap,
    required this.onReportProblem,
  });

  final EsimStatus status;
  final bool refreshing;
  final Duration cooldownRemaining;
  final VoidCallback onRefresh;
  final EsimVerdict verdict;
  final ValueChanged<String> onInstall;
  final void Function(String label, String value) onCopy;
  final VoidCallback onOpenSetupGuide;
  final List<TopupOption> topupOptions;
  final ValueChanged<TopupOption> onTopupOptionTap;
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    final canRefresh = !refreshing && cooldownRemaining == Duration.zero;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(status.product.title, style: AppTypography.title()),
          const SizedBox(height: 4),
          Text(status.status.label,
              style: AppTypography.label(color: AppColors.inkMuted)),
          if (showsTelemetryStaleBanner(status.telemetry)) ...[
            const SizedBox(height: 16),
            InfoBox(
              icon: Icons.wifi_off,
              text: status.telemetry.fetchedAt != null
                  ? 'Live usage temporarily unavailable -- last updated '
                      '${DateFormat.yMMMd().add_jm().format(status.telemetry.fetchedAt!.toLocal())}.'
                  : 'Live usage temporarily unavailable.',
            ),
          ],
          const SizedBox(height: 24),
          UsageRing(
            fraction: usageFraction(status.usage),
            centerText: usageCenterText(status.usage),
          ),
          const SizedBox(height: 16),
          Text(validityCountdownLabel(status.validity, DateTime.now()),
              style: AppTypography.body(color: AppColors.inkMuted)),
          const SizedBox(height: 24),
          PillButton(
            key: const ValueKey('esim-refresh-button'),
            label: refreshing
                ? 'Refreshing...'
                : cooldownRemaining > Duration.zero
                    ? 'Refresh (wait ${cooldownRemaining.inSeconds + 1}s)'
                    : 'Refresh',
            variant: PillButtonVariant.secondary,
            onPressed: canRefresh ? onRefresh : null,
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.line),
          const SizedBox(height: 24),
          if (lifecycleBannerMessage(status.esimStatus) case final message?)
            _LifecycleBanner(
                key: const ValueKey('esim-lifecycle-banner'), message: message)
          else ...[
            EsimQr(
              data: status.qrCodeData.isNotEmpty
                  ? status.qrCodeData
                  : status.lpaString,
            ),
            const SizedBox(height: 20),
            _InstallButton(
              verdict: verdict,
              lpaString: status.lpaString,
              onInstall: onInstall,
            ),
            const SizedBox(height: 20),
            InfoBox(
              icon: Icons.warning_amber_outlined,
              text: 'You can only install this eSIM once. If you remove it '
                  'from your device, it cannot be reinstalled -- contact '
                  'support if that happens.',
            ),
            const SizedBox(height: 16),
            _CopyRow(
              label: 'SM-DP+ address',
              value: status.smdpAddress,
              onCopy: () => onCopy('SM-DP+ address', status.smdpAddress),
            ),
            if (status.matchingId != null)
              _CopyRow(
                label: 'Matching ID',
                value: status.matchingId!,
                onCopy: () => onCopy('Matching ID', status.matchingId!),
              ),
            _CopyRow(
              label: 'Activation code (LPA)',
              value: status.lpaString,
              onCopy: () => onCopy('Activation code', status.lpaString),
            ),
            const SizedBox(height: 16),
            PillButton(
              key: const ValueKey('esim-setup-guide-link'),
              label: 'View setup guide',
              variant: PillButtonVariant.text,
              onPressed: onOpenSetupGuide,
            ),
          ],
          if (topupOptions.isNotEmpty &&
              !installAndTopupDisabled(status.esimStatus)) ...[
            const SizedBox(height: 32),
            const Divider(color: AppColors.line),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Top up', style: AppTypography.headline()),
            ),
            const SizedBox(height: 8),
            for (final option in topupOptions)
              _TopupOptionRow(
                key: ValueKey('topup-option-${option.packageCode}'),
                option: option,
                onTap: () => onTopupOptionTap(option),
              ),
          ],
          if (hasHistorySection(status.history, status.dailyBreakdown)) ...[
            const SizedBox(height: 32),
            const Divider(color: AppColors.line),
            const SizedBox(height: 16),
            if (status.dailyBreakdown.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Daily usage', style: AppTypography.headline()),
              ),
              const SizedBox(height: 8),
              for (final entry in status.dailyBreakdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(formatHistoryEntry(entry),
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (status.history.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Install history', style: AppTypography.headline()),
              ),
              const SizedBox(height: 8),
              for (final entry in status.history)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(formatHistoryEntry(entry),
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 32),
          const Divider(color: AppColors.line),
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey('esim-report-problem-button'),
            label: 'Report a problem',
            variant: PillButtonVariant.text,
            onPressed: onReportProblem,
          ),
        ],
      ),
    );
  }
}

class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: AppTypography.caption(color: AppColors.danger))),
        ],
      ),
    );
  }
}

class _InstallButton extends StatelessWidget {
  const _InstallButton({
    required this.verdict,
    required this.lpaString,
    required this.onInstall,
  });

  final EsimVerdict verdict;
  final String lpaString;
  final ValueChanged<String> onInstall;

  @override
  Widget build(BuildContext context) {
    final installUrl = buildInstallUrl(lpaString, isIOS: Platform.isIOS);
    if (installUrl != null && verdict.kind == EsimVerdictKind.supported) {
      return PillButton(
        key: const ValueKey('esim-one-tap-install-button'),
        label: 'Install eSIM',
        onPressed: () => onInstall(installUrl),
      );
    }
    final explanation = verdict.kind == EsimVerdictKind.notSupported
        ? "Your device isn't eSIM-compatible -- use the codes below to "
            'install on a compatible device instead.'
        : "We couldn't confirm 1-tap install on this device -- use the "
            'codes below instead.';
    return Text(
      explanation,
      key: const ValueKey('esim-install-explanation'),
      textAlign: TextAlign.center,
      style: AppTypography.caption(color: AppColors.inkMuted),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption(color: AppColors.inkMuted)),
                Text(value,
                    style: AppTypography.body(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('esim-copy-$label'),
            icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _TopupOptionRow extends StatelessWidget {
  const _TopupOptionRow({super.key, required this.option, required this.onTap});

  final TopupOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final rateAsync = ref.watch(selectedCurrencyRateProvider);
      final currencyAsync = ref.watch(currencyPreferenceProvider);
      final priceText = switch ((rateAsync, currencyAsync)) {
        (AsyncData(value: final rate), AsyncData(value: final code)) =>
          formatMoney(option.retailPrice, currencyCode: code, rateToBase: rate),
        _ => '',
      };
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title, style: AppTypography.body()),
                    Text('${option.validityDays} days',
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                  ],
                ),
              ),
              Text(priceText, style: AppTypography.body()),
            ],
          ),
        ),
      );
    });
  }
}
