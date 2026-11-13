import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/main.dart';

void main() {
  testWidgets('TriptelApp renders without crashing',
      (WidgetTester tester) async {
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
          // Avoids a real Dio network call during the test (Home's hero
          // renders its popular-destinations list eagerly).
          popularCountriesProvider.overrideWith((ref) async => const []),
        ],
        child: const TriptelApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
