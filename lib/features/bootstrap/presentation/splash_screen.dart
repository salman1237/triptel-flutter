import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';

/// Shown while `/settings/public`, `/rates`, `/languages` load (FR-002).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.night,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Triptel',
              key: const ValueKey('splash-wordmark'),
              style: AppTypography.title(color: AppColors.surface),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
                color: AppColors.surface, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
