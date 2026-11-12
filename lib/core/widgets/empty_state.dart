import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pill_button.dart';

/// Icon-in-circle + one sentence + CTA, Design_System.md §3.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.onCtaPressed,
  });

  final IconData icon;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.lilac100, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.inkMuted),
          ),
          if (ctaLabel != null) ...[
            const SizedBox(height: 16),
            PillButton(
                label: ctaLabel!, onPressed: onCtaPressed, fullWidth: false),
          ],
        ],
      ),
    );
  }
}
