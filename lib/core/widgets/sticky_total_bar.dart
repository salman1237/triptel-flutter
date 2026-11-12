import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pill_button.dart';

/// Bottom-anchored bar: total + optional savings note + pill CTA (checkout).
class StickyTotalBar extends StatelessWidget {
  const StickyTotalBar({
    super.key,
    required this.totalText,
    required this.ctaLabel,
    this.savingsText,
    this.onPressed,
  });

  final String totalText;
  final String ctaLabel;
  final String? savingsText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [appCardShadow],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(totalText, style: AppTypography.headline()),
                  if (savingsText != null)
                    Text(savingsText!,
                        style: AppTypography.caption(color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PillButton(label: ctaLabel, onPressed: onPressed),
            ),
          ],
        ),
      ),
    );
  }
}
