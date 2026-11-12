import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_loader.dart';
import 'package:triptel/features/bootstrap/data/bootstrap_api.dart';
import 'package:triptel/features/bootstrap/data/bootstrap_cache.dart';
import 'package:triptel/features/bootstrap/data/models/currency_rate.dart';
import 'package:triptel/features/bootstrap/data/models/language.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

class _FakeBootstrapApi implements BootstrapApi {
  _FakeBootstrapApi({this.shouldFail = false});
  final bool shouldFail;

  static const settings = PublicSettings(
    platformName: 'Triptel',
    maintenanceMode: false,
    defaultCurrency: 'EUR',
    supportEmail: 'support@triptel.co',
  );
  static const rates = [CurrencyRate(currencyCode: 'BDT', rateToBase: 141.65)];
  static const languages = [
    Language(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        isActive: true,
        isRtl: false),
  ];

  @override
  Future<PublicSettings> fetchPublicSettings() async {
    if (shouldFail) throw Exception('network down');
    return settings;
  }

  @override
  Future<List<CurrencyRate>> fetchRates() async {
    if (shouldFail) throw Exception('network down');
    return rates;
  }

  @override
  Future<List<Language>> fetchLanguages() async {
    if (shouldFail) throw Exception('network down');
    return languages;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadBootstrap', () {
    test('fetches fresh data and caches it when the network succeeds',
        () async {
      SharedPreferences.setMockInitialValues({});
      final cache = BootstrapCache(await SharedPreferences.getInstance());
      final api = _FakeBootstrapApi();

      final result = await loadBootstrap(api: api, cache: cache);

      expect(result.fromCache, isFalse);
      expect(result.settings.platformName, 'Triptel');
      expect(cache.load(), isNotNull);
    });

    test('falls back to cache when the network call fails', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = BootstrapCache(prefs);
      await loadBootstrap(
          api: _FakeBootstrapApi(), cache: cache); // warms the cache

      final result = await loadBootstrap(
          api: _FakeBootstrapApi(shouldFail: true), cache: cache);

      expect(result.fromCache, isTrue);
      expect(result.settings.platformName, 'Triptel');
    });

    test('rethrows when the network fails and there is no cache', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = BootstrapCache(await SharedPreferences.getInstance());

      expect(
        () => loadBootstrap(
            api: _FakeBootstrapApi(shouldFail: true), cache: cache),
        throwsA(isA<Exception>()),
      );
    });
  });
}
