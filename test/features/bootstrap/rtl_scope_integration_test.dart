import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/i18n/rtl_scope.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/language.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/bootstrap/presentation/bootstrap_gate.dart';
import 'package:triptel/features/bootstrap/presentation/maintenance_screen.dart';

const _child = Text('home-content', key: ValueKey('home-content'));

final _languages = [
  const Language(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      isActive: true,
      isRtl: false),
  const Language(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      isActive: true,
      isRtl: true),
];

BootstrapData _data({required bool maintenance}) => BootstrapData(
      settings: PublicSettings(
        platformName: 'Triptel',
        maintenanceMode: maintenance,
        defaultCurrency: 'EUR',
        supportEmail: maintenance ? 'support@triptel.co' : null,
      ),
      rates: const [],
      languages: _languages,
      fromCache: false,
    );

void main() {
  testWidgets(
      'FR-006b: MaintenanceScreen renders RTL when Arabic is the saved '
      'language', (tester) async {
    SharedPreferences.setMockInitialValues({'language.selected': 'ar'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider
              .overrideWith((ref) async => _data(maintenance: true)),
        ],
        child: const MaterialApp(
          home: RtlScope(child: BootstrapGate(child: _child)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MaintenanceScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets(
      'FR-006b: MaintenanceScreen stays LTR when English is the saved '
      'language', (tester) async {
    SharedPreferences.setMockInitialValues({'language.selected': 'en'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider
              .overrideWith((ref) async => _data(maintenance: true)),
        ],
        child: const MaterialApp(
          home: RtlScope(child: BootstrapGate(child: _child)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MaintenanceScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets(
      'FR-006b: normal app content still renders RTL for Arabic (regression '
      'guard for the pre-existing FR-006 behavior)', (tester) async {
    SharedPreferences.setMockInitialValues({'language.selected': 'ar'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider
              .overrideWith((ref) async => _data(maintenance: false)),
        ],
        child: const MaterialApp(
          home: RtlScope(child: BootstrapGate(child: _child)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-content')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('home-content'))),
      TextDirection.rtl,
    );
  });
}
