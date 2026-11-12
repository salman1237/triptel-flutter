import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Displays a formatted price, with an optional struck-through original price
/// when discounted. Formatting/conversion is the caller's job (core/money, FR-005).
class PriceText extends StatelessWidget {
  const PriceText(
      {super.key, required this.price, this.originalPrice, this.style});

  final String price;
  final String? originalPrice;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(price, style: style ?? AppTypography.headline()),
        if (originalPrice != null) ...[
          const SizedBox(width: 6),
          Text(
            originalPrice!,
            style: AppTypography.caption(color: AppColors.inkMuted).copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
