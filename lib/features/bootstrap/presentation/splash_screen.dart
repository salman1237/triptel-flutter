import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

/// Shown while `/settings/public`, `/rates`, `/languages` load (FR-002).
/// The real Triptel wordmark (`GET /settings/public`'s `logo_light`
/// field -- the full "triptel" lockup, dark text for light backgrounds),
/// bundled as a static asset since the splash itself runs before that
/// endpoint resolves. See DECISIONS.md for the static-snapshot caveat.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/logo_light.png',
              key: const ValueKey('splash-logo'),
              width: 220,
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
