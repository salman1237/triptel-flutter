import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/i18n/translations_api.dart';
import 'package:triptel/core/i18n/translations_cache.dart';
import 'package:triptel/core/i18n/translations_loader.dart';

class _FakeTranslationsApi implements TranslationsApi {
  _FakeTranslationsApi({this.shouldFail = false});
  final bool shouldFail;

  static const namespaces = {
    'common': {'save': 'Save'},
  };

  @override
  Future<Map<String, dynamic>> fetchTranslations(String languageCode) async {
    if (shouldFail) throw Exception('network down');
    return namespaces;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadTranslations', () {
    test('fetches fresh data and caches it when the network succeeds',
        () async {
      SharedPreferences.setMockInitialValues({});
      final cache = TranslationsCache(await SharedPreferences.getInstance());

      final result = await loadTranslations(
        languageCode: 'en',
        api: _FakeTranslationsApi(),
        cache: cache,
      );

      expect(result, _FakeTranslationsApi.namespaces);
      expect(cache.load('en'), isNotNull);
    });

    test('falls back to cache when the network call fails', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = TranslationsCache(await SharedPreferences.getInstance());
      await loadTranslations(
          languageCode: 'en', api: _FakeTranslationsApi(), cache: cache);

      final result = await loadTranslations(
        languageCode: 'en',
        api: _FakeTranslationsApi(shouldFail: true),
        cache: cache,
      );

      expect(result, _FakeTranslationsApi.namespaces);
    });

    test('rethrows when the network fails and there is no cache', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = TranslationsCache(await SharedPreferences.getInstance());

      expect(
        () => loadTranslations(
          languageCode: 'ar',
          api: _FakeTranslationsApi(shouldFail: true),
          cache: cache,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('caches independently per language code', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = TranslationsCache(await SharedPreferences.getInstance());
      await loadTranslations(
          languageCode: 'en', api: _FakeTranslationsApi(), cache: cache);

      expect(cache.load('en'), isNotNull);
      expect(cache.load('ar'), isNull);
    });
  });
}
