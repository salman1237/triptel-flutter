import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/i18n/language_pill_switcher.dart';
import 'package:triptel/core/i18n/rtl_scope.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/language.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

final _sampleBootstrap = BootstrapData(
  settings: const PublicSettings(
      platformName: 'Triptel', maintenanceMode: false, defaultCurrency: 'EUR'),
  rates: const [],
  languages: const [
    Language(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        isActive: true,
        isRtl: false),
    Language(
        code: 'ar',
        name: 'Arabic',
        nativeName: 'العربية',
        isActive: true,
        isRtl: true),
  ],
  fromCache: false,
);

void main() {
  testWidgets('shows the default language, switches, and flips text direction',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
        ],
        child: const MaterialApp(
          home: RtlScope(
            child: Scaffold(
              body: Align(
                  alignment: Alignment.topRight, child: LanguagePillSwitcher()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(LanguagePillSwitcher))),
        TextDirection.ltr);

    await tester.tap(find.byKey(const ValueKey('language-pill')));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-option-ar')));
    await tester.pumpAndSettle();

    expect(find.text('AR'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(LanguagePillSwitcher))),
        TextDirection.rtl);
  });
}
