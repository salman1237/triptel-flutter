import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/models/public_settings.dart';

/// FR-003: `maintenance_mode == true` blocks the whole app behind this
/// screen, with support contacts (hidden when null, API.md §1) and retry.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen(
      {super.key, required this.settings, required this.onRetry});

  final PublicSettings settings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('maintenance-screen'),
      backgroundColor: AppColors.lilac50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_outlined,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  "We're down for maintenance",
                  textAlign: TextAlign.center,
                  style: AppTypography.headline(),
                ),
                const SizedBox(height: 8),
                Text(
                  '${settings.platformName} is briefly unavailable while we make things better. '
                  'Please try again shortly.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
                if (settings.supportPhone != null ||
                    settings.supportEmail != null) ...[
                  const SizedBox(height: 20),
                  InfoBox(
                    icon: Icons.support_agent_outlined,
                    text: [
                      if (settings.supportEmail != null) settings.supportEmail!,
                      if (settings.supportPhone != null) settings.supportPhone!,
                    ].join(' · '),
                  ),
                ],
                const SizedBox(height: 24),
                PillButton(
                    label: 'Retry', onPressed: onRetry, fullWidth: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
