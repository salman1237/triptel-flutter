import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pill_button.dart';

/// Error placeholder with a retry CTA.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.ink),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            PillButton(label: 'Retry', onPressed: onRetry, fullWidth: false),
          ],
        ],
      ),
    );
  }
}
