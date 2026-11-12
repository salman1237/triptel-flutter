import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/currency_rate.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

final _sampleBootstrap = BootstrapData(
  settings: const PublicSettings(
      platformName: 'Triptel', maintenanceMode: false, defaultCurrency: 'EUR'),
  rates: const [
    CurrencyRate(currencyCode: 'BDT', rateToBase: 141.656046),
    CurrencyRate(currencyCode: 'USD', rateToBase: 1.08),
  ],
  languages: const [],
  fromCache: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to the platform currency when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(container.dispose);

    final code = await container.read(currencyPreferenceProvider.future);
    expect(code, 'EUR');
  });

  test('select() persists the choice so the next read picks it up', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(container.dispose);

    await container.read(currencyPreferenceProvider.future);
    await container.read(currencyPreferenceProvider.notifier).select('BDT');
    expect(container.read(currencyPreferenceProvider).value, 'BDT');

    // A fresh container simulates the next app launch reading the same prefs.
    final relaunched = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith((ref) async => _sampleBootstrap)
      ],
    );
    addTearDown(relaunched.dispose);
    final reloaded = await relaunched.read(currencyPreferenceProvider.future);
    expect(reloaded, 'BDT');
  });
}
