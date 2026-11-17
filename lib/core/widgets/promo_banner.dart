import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Warm gradient CTA card for a real promotional offer (2026-11-17 UI
/// refresh, Design_System.md §5) -- icon, title, optional subtitle, and a
/// light pill CTA on a `warning -> offerDeep` gradient. Only ever wired up
/// with real campaign content from the backend; never fabricated copy
/// (Rules.md -- same discipline as every other screen this session).
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warning, AppColors.offerDeep],
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.surface, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.label(color: AppColors.surface)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppTypography.caption(
                          color: AppColors.surface.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              key: const ValueKey('promo-banner-cta-button'),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(ctaLabel,
                    style: AppTypography.label(color: AppColors.offerDeep)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
