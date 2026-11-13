import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/app/router.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/compatibility/presentation/compatibility_promo_card.dart';
import 'package:triptel/features/compatibility/presentation/compatibility_result_screen.dart';
import 'package:triptel/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // `appRouter` is a module-level singleton (lib/app/router.dart), so its
  // navigation state otherwise leaks between tests in this file.
  addTearDown(() => appRouter.go('/home'));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWith(
          (ref) async => const BootstrapData(
            settings: PublicSettings(
              platformName: 'Triptel',
              maintenanceMode: false,
              defaultCurrency: 'EUR',
            ),
            rates: [],
            languages: [],
            fromCache: false,
          ),
        ),
        // Avoids the real native method channel, which has no handler in a
        // widget test and would leave CompatibilityResultScreen's loading
        // spinner animating forever (pumpAndSettle never settles).
        esimVerdictProvider.overrideWith((ref) => SynchronousFuture(
              const EsimVerdict(
                kind: EsimVerdictKind.notSupported,
                deviceLabel: 'test device',
                reason: 'This device has no eSIM hardware.',
              ),
            )),
      ],
      child: const TriptelApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'FR-953: Home shows the compatibility promo card and it navigates',
      (tester) async {
    await _pumpApp(tester);

    expect(find.byType(CompatibilityPromoCard), findsOneWidget);
    expect(find.text('Check device compatibility'), findsOneWidget);

    await tester.tap(find.byType(CompatibilityPromoCard));
    await tester.pumpAndSettle();

    expect(find.byType(CompatibilityResultScreen), findsOneWidget);
  });

  testWidgets(
      'FR-953: Account also shows the compatibility promo card and it navigates',
      (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.byType(CompatibilityPromoCard), findsOneWidget);

    await tester.tap(find.byType(CompatibilityPromoCard));
    await tester.pumpAndSettle();

    expect(find.byType(CompatibilityResultScreen), findsOneWidget);
  });
}
