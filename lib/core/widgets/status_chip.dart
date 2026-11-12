import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

enum StatusTone { success, info, warning, danger }

/// Status chip, Design_System.md §3: Active/Installed success, Not installed sky,
/// Preparing warning, Suspended/Revoked/Cancelled/Expired/Failed danger.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTypography.caption(color: color)),
    );
  }
}
