import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

enum PillButtonVariant { primary, secondary, text }

/// Full-width (by default) pill CTA, Design_System.md §3.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.fullWidth = true,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final bool fullWidth;

  /// Optional icon/logo shown before the label (e.g. Google's "G" mark).
  final Widget? leading;

  Widget _labelRow(Color color) {
    final text = Text(label, style: AppTypography.label(color: color));
    if (leading == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [leading!, const SizedBox(width: 10), text],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (variant) {
      PillButtonVariant.primary => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            elevation: 0,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? AppColors.primaryDeep
                  : AppColors.primary,
            ),
          ),
          child: _labelRow(AppColors.surface),
        ),
      PillButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.lilac200, width: 1.5),
          ),
          child: _labelRow(AppColors.primary),
        ),
      PillButtonVariant.text => TextButton(
          onPressed: onPressed,
          child: _labelRow(AppColors.primary),
        ),
    };

    if (!fullWidth || variant == PillButtonVariant.text) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}
