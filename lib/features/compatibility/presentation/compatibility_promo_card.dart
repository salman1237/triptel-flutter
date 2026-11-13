import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';

/// FR-953: the Home promo card ("device check", Design_System.md's Home
/// hero spec) and Account's compatibility entry point both reuse this —
/// a tappable white card routing to FR-951's compatibility screen.
class CompatibilityPromoCard extends StatelessWidget {
  const CompatibilityPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('compatibility-promo-card'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => context.push('/compatibility'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [appCardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.lilac100, shape: BoxShape.circle),
              child: const Icon(Icons.phone_iphone,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check device compatibility',
                      style: AppTypography.label()),
                  const SizedBox(height: 2),
                  Text(
                    "Make sure your phone supports eSIM before you buy",
                    style: AppTypography.caption(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
