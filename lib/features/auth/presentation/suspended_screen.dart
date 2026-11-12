import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../bootstrap/application/bootstrap_providers.dart';

/// FR-109: shown on a 403 "Account suspended" (API.md §0.1 — the app has
/// already signed the user out by this point). Support contacts come from
/// `/settings/public`, same null-hiding rule as FR-003's maintenance screen.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(bootstrapProvider).value?.settings;

    return Scaffold(
      key: const ValueKey('suspended-screen'),
      backgroundColor: AppColors.lilac50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_outlined,
                    size: 56, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Account suspended',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline()),
                const SizedBox(height: 8),
                Text(
                  "Your account has been suspended. Contact support if you think this isn't right.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
                if (settings != null &&
                    (settings.supportEmail != null ||
                        settings.supportPhone != null)) ...[
                  const SizedBox(height: 20),
                  InfoBox(
                    icon: Icons.support_agent_outlined,
                    text: [
                      if (settings.supportEmail != null) settings.supportEmail!,
                      if (settings.supportPhone != null) settings.supportPhone!,
                    ].join(' · '),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
