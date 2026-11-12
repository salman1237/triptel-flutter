import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/money/currency_pill_switcher.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/currency_rate.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

final _sampleBootstrap = BootstrapData(
  settings: const PublicSettings(
    platformName: 'Triptel',
    maintenanceMode: false,
    defaultCurrency: 'EUR',
  ),
  rates: const [CurrencyRate(currencyCode: 'BDT', rateToBase: 141.656046)],
  languages: const [],
  fromCache: false,
);

void main() {
  testWidgets('shows the default currency and switches on selection',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
        ],
        child: const MaterialApp(
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topRight,
                  child: CurrencyPillSwitcher())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EUR €'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('currency-pill')));
    await tester.pumpAndSettle();

    expect(find.text('Choose currency'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('currency-option-BDT')));
    await tester.pumpAndSettle();

    expect(find.text('BDT ৳'), findsOneWidget);
  });
}
