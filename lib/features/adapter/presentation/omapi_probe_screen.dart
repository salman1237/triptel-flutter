import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/omapi_probe_result.dart';
import '../application/omapi_providers.dart';

/// FR-L905: shows the real, observed result of trying to open an OMAPI
/// channel to a removable eUICC card in the phone's SIM tray -- a
/// diagnostic, not a decision screen. The result is whatever the device
/// actually reports; this screen never guesses or assumes an outcome.
class OmapiProbeScreen extends ConsumerWidget {
  const OmapiProbeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final probeAsync = ref.watch(omapiProbeProvider);

    return TriptelScaffold(
      key: const ValueKey('omapi-probe-screen'),
      appBar: AppBar(title: const Text('eSIM adapter diagnostic')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Checks whether this app can reach the eUICC card in the SIM '
            "tray. This is a real device test, not a prediction -- the "
            "card's own access rules decide the answer.",
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          switch (probeAsync) {
            AsyncData(:final value) => _ProbeResultCard(result: value),
            AsyncError() => ErrorState(
                message: "Couldn't run the probe.",
                onRetry: () => ref.invalidate(omapiProbeProvider),
              ),
            _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
          },
          const SizedBox(height: 20),
          PillButton(
            key: const ValueKey('omapi-probe-rerun'),
            label: 'Run again',
            variant: PillButtonVariant.secondary,
            onPressed: () => ref.invalidate(omapiProbeProvider),
          ),
        ],
      ),
    );
  }
}

class _ProbeResultCard extends StatelessWidget {
  const _ProbeResultCard({required this.result});

  final OmapiProbeResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('omapi-probe-result'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: result.available ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.available ? Icons.check_circle : Icons.cancel,
                color: result.available ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.available ? 'Access granted' : 'Access not granted',
                  style: AppTypography.body()
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.summary(), style: AppTypography.body()),
          if (result.readerNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Readers found', style: AppTypography.label()),
            Text(result.readerNames.join(', '), style: AppTypography.caption()),
          ],
          if (result.error != null) ...[
            const SizedBox(height: 12),
            Text('Raw error', style: AppTypography.label()),
            Text(result.error!,
                style: AppTypography.caption(color: AppColors.inkMuted)),
          ],
          if (result.selectResponseHex != null) ...[
            const SizedBox(height: 12),
            Text('ISD-R SELECT response', style: AppTypography.label()),
            Text(result.selectResponseHex!,
                style: AppTypography.caption(color: AppColors.inkMuted)),
          ],
        ],
      ),
    );
  }
}
