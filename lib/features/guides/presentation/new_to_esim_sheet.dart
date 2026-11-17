import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';

/// FR-902: "New to eSIM?" sheet -- short explainer + links to FR-901's
/// setup guide and FR-952's compatibility list. No general `/support`
/// screen exists yet (FR-1101/1102 `not_started`), so the support line
/// stays plain text rather than a dead link (same disclosed-limitation
/// pattern as FR-901, see DECISIONS.md).
Future<void> showNewToEsimSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NewToEsimSheet(),
  );
}

class NewToEsimSheet extends StatelessWidget {
  const NewToEsimSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('new-to-esim-sheet'),
      decoration: const BoxDecoration(
        color: AppColors.lilac50,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 20, AppSpacing.gutter, AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('New to eSIM?', style: AppTypography.headline()),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "An eSIM is a digital SIM -- no physical card, no swapping "
              'trays. Your phone needs to support eSIM, and you install it '
              'with a QR code or a one-tap link instead of inserting a '
              'card.',
              style: AppTypography.body(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            PillButton(
              key: const ValueKey('new-to-esim-guide-button'),
              label: 'View setup guide',
              onPressed: () {
                Navigator.of(context).maybePop();
                context.push('/guides/esim-setup-guide');
              },
            ),
            const SizedBox(height: 10),
            PillButton(
              key: const ValueKey('new-to-esim-compatibility-button'),
              label: 'Check device compatibility',
              variant: PillButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).maybePop();
                context.push('/compatibility/devices');
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Still unsure? Contact Support and we\'ll help you pick the '
              'right plan.',
              textAlign: TextAlign.center,
              style: AppTypography.caption(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
