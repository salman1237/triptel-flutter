import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'status_chip.dart';

/// Small coloured dot + plain-text label (2026-11-17 UI refresh,
/// Design_System.md §5) -- a lighter-weight sibling to `StatusChip` for
/// live/presence-style indicators ("Active", "Online") on a card header,
/// where a full filled pill would be too heavy. `StatusChip` stays the
/// right choice for list-row/filter status (Active/Installed/Preparing/...).
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  Color get _color => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.info => AppColors.sky,
        StatusTone.warning => AppColors.warning,
        StatusTone.danger => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption(color: AppColors.inkMuted)),
      ],
    );
  }
}
