import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/compatibility_providers.dart';
import '../application/esim_verdict.dart';

/// FR-951: Eskimo's result-tinted compatibility screen, re-skinned in
/// Triptel tokens (Rules.md: follow Eskimo's patterns, never copy its
/// assets/copy/colours). Reads the already-built FR-950 verdict.
class CompatibilityResultScreen extends ConsumerWidget {
  const CompatibilityResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verdictAsync = ref.watch(esimVerdictProvider);

    return Scaffold(
      key: const ValueKey('compatibility-result-screen'),
      backgroundColor: AppColors.lilac50,
      body: SafeArea(
        bottom: false,
        child: switch (verdictAsync) {
          AsyncData(:final value) => _ResultBody(verdict: value),
          AsyncError() => Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: ErrorState(
                message: "We couldn't check this device's eSIM support.",
                onRetry: () => ref.invalidate(esimVerdictProvider),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.verdict});

  final EsimVerdict verdict;

  Color get _tint => switch (verdict.kind) {
        EsimVerdictKind.supported => AppColors.success,
        EsimVerdictKind.unknown => AppColors.warning,
        EsimVerdictKind.notSupported => AppColors.danger,
      };

  IconData get _icon => switch (verdict.kind) {
        EsimVerdictKind.supported => Icons.check_circle_outline,
        EsimVerdictKind.unknown => Icons.help_outline,
        EsimVerdictKind.notSupported => Icons.error_outline,
      };

  String get _headline => switch (verdict.kind) {
        EsimVerdictKind.supported => 'Your device supports eSIM',
        EsimVerdictKind.unknown => "We couldn't confirm eSIM support",
        EsimVerdictKind.notSupported => 'Your device does not support eSIM',
      };

  @override
  Widget build(BuildContext context) {
    final tint = _tint;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tint.withValues(alpha: 0.12),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              8,
              AppSpacing.gutter,
              32,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: AppColors.ink),
                  ),
                ),
                Icon(_icon, size: 72, color: tint),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              24,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StatusChip(label: verdict.deviceLabel, tone: StatusTone.info),
                const SizedBox(height: 16),
                Text(
                  _headline,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline(),
                ),
                const SizedBox(height: 8),
                Text(
                  verdict.reason,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 24),
                const InfoBox(
                  text: "Some eSIM devices are locked to a specific "
                      'carrier. Contact your provider to unlock it if you '
                      "can't install your eSIM.",
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'View supported devices',
                  variant: PillButtonVariant.secondary,
                  onPressed: () => context.push('/compatibility/devices'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
