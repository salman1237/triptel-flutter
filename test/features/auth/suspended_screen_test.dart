import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/auth/presentation/suspended_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

BootstrapData _bootstrap({String? supportEmail, String? supportPhone}) =>
    BootstrapData(
      settings: PublicSettings(
        platformName: 'Triptel',
        maintenanceMode: false,
        defaultCurrency: 'EUR',
        supportEmail: supportEmail,
        supportPhone: supportPhone,
      ),
      rates: const [],
      languages: const [],
      fromCache: false,
    );

void main() {
  testWidgets('shows the support contact when present', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => _bootstrap(supportEmail: 'support@triptel.co'),
          ),
        ],
        child: const MaterialApp(home: SuspendedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account suspended'), findsOneWidget);
    expect(find.text('support@triptel.co'), findsOneWidget);
  });

  testWidgets('hides the contact box when no support fields are set',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith((ref) async => _bootstrap())
        ],
        child: const MaterialApp(home: SuspendedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account suspended'), findsOneWidget);
    expect(find.byIcon(Icons.support_agent_outlined), findsNothing);
  });
}
