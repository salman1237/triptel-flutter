import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/esim_status_providers.dart';
import '../application/esim_usage_shape.dart';
import '../data/models/esim_status.dart';

/// FR-403: eSIM detail -- usage. `GET /esims/{id}/status`: usage ring/bar
/// (allowance incl. top-ups; none for unlimited), remaining, validity
/// countdown or "starts on install", status label, telemetry-stale banner,
/// manual refresh (`POST /refresh`, 30s client-side cooldown). FR-404
/// (install), FR-405 (lifecycle banners) and FR-406/407 (history/top-up)
/// are separate, not-yet-built sections of this same screen.
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

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(esimStatusProvider(widget.esimId));

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
  });

  final EsimStatus status;
  final bool refreshing;
  final Duration cooldownRemaining;
  final VoidCallback onRefresh;

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
        ],
      ),
    );
  }
}
