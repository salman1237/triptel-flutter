import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/esim_setup_guide_content.dart';

/// FR-901: eSIM setup guide, ported from the web's static
/// `/guides/esim-setup-guide` page (no backend endpoint -- same copy on
/// both platforms). Replaces FR-404's previous "open the web page in an
/// external browser" placeholder (`esim_install_links.dart`'s
/// `setupGuideUrl()`), now that this screen exists in-app.
class EsimSetupGuideScreen extends StatelessWidget {
  const EsimSetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('esim-setup-guide-screen'),
      appBar: AppBar(title: const Text('eSIM Setup Guide')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Takes about two minutes. Install it a day or two before you '
            "travel if you can -- it won't start using up your validity "
            'until it actually connects to a network.',
            style: AppTypography.body(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          InfoBox(
            icon: Icons.warning_amber_outlined,
            text: 'An eSIM can only be installed once. If you delete it '
                "from your phone, it usually can't be reinstalled -- check "
                'your plan details, and contact Support before removing '
                'it.',
          ),
          const SizedBox(height: 24),
          Text('iPhone', style: AppTypography.title()),
          const SizedBox(height: 8),
          _StepList(
              key: const ValueKey('esim-setup-guide-ios-steps'),
              steps: iosSetupSteps),
          const SizedBox(height: 24),
          Text('Android', style: AppTypography.title()),
          const SizedBox(height: 8),
          _StepList(
              key: const ValueKey('esim-setup-guide-android-steps'),
              steps: androidSetupSteps),
          const SizedBox(height: 4),
          Text(
            'Menu names vary slightly by brand (Samsung, Xiaomi, Oppo, '
            'etc.) -- look for "eSIM" or "Add SIM" under your SIM/network '
            'settings.',
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          Text("If it's not connecting", style: AppTypography.title()),
          const SizedBox(height: 8),
          ListGroup(
            key: const ValueKey('esim-setup-guide-troubleshooting'),
            children: [
              for (final item in setupGuideTroubleshooting)
                ListRow(icon: Icons.wifi_outlined, title: item),
            ],
          ),
          const SizedBox(height: 24),
          PillButton(
            key: const ValueKey('esim-setup-guide-compatibility-link'),
            label: 'Check device compatibility',
            variant: PillButtonVariant.text,
            fullWidth: false,
            onPressed: () => context.push('/compatibility/devices'),
          ),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.lilac100,
                  child: Text('${i + 1}',
                      style: AppTypography.caption(color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(steps[i], style: AppTypography.body()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
