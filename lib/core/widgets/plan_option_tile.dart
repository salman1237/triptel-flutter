import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'price_text.dart';

/// Radio-style plan row, Design_System.md §2 (country plans bottom panel).
class PlanOptionTile extends StatelessWidget {
  const PlanOptionTile({
    super.key,
    required this.title,
    required this.priceText,
    this.coverageLabel,
    this.originalPriceText,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String priceText;
  final String? coverageLabel;
  final String? originalPriceText;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.lilac100 : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body()),
                  if (coverageLabel != null)
                    Text(coverageLabel!,
                        style: AppTypography.caption(color: AppColors.primary)),
                ],
              ),
            ),
            PriceText(price: priceText, originalPrice: originalPriceText),
          ],
        ),
      ),
    );
  }
}
