import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/install/install_link.dart';
import '../../../core/install/url_launcher_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/application/esim_verdict.dart';
import '../application/esim_install_links.dart';
import '../application/esim_status_providers.dart';
import '../application/esim_usage_shape.dart';
import '../data/models/esim_status.dart';

/// FR-403: eSIM detail -- usage. `GET /esims/{id}/status`: usage ring/bar
/// (allowance incl. top-ups; none for unlimited), remaining, validity
/// countdown or "starts on install", status label, telemetry-stale banner,
/// manual refresh (`POST /refresh`, 30s client-side cooldown).
/// FR-404: install section -- QR reveal, 1-tap install (gated by FR-950's
/// verdict, per Rules.md's compatibility rule: detection only ever gates
/// the 1-tap button, never the QR/manual codes, which stay useful for
/// installing on a different device), manual SM-DP+/matching ID/LPA copy,
/// an "install only once" warning, and a link to the web setup guide
/// (FR-901 isn't ported into the app yet). FR-405 (lifecycle banners) and
/// FR-406/407 (history/top-up) are separate, not-yet-built sections of
/// this same screen.
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

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(esimStatusProvider(widget.esimId));
    final verdictAsync = ref.watch(esimVerdictProvider);

    return TriptelScaffold(
      key: const ValueKey('esim-detail-screen'),
      appBar: AppBar(title: const Text('eSIM details')),
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
  });

  final EsimStatus status;
  final bool refreshing;
  final Duration cooldownRemaining;
  final VoidCallback onRefresh;
  final EsimVerdict verdict;
  final ValueChanged<String> onInstall;
  final void Function(String label, String value) onCopy;
  final VoidCallback onOpenSetupGuide;

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
