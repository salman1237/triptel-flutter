import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/i18n/language_providers.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to English when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(languagePreferenceProvider.future), 'en');
    expect(await container.read(isRtlProvider.future), isFalse);
  });

  test('select() persists the choice and flips RTL', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(container.dispose);

    await container.read(languagePreferenceProvider.future);
    await container.read(languagePreferenceProvider.notifier).select('ar');
    expect(container.read(languagePreferenceProvider).value, 'ar');
    expect(await container.read(isRtlProvider.future), isTrue);

    final relaunched = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(relaunched.dispose);
    expect(await relaunched.read(languagePreferenceProvider.future), 'ar');
  });
}
