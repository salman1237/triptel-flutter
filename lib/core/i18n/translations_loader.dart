import 'translations_api.dart';
import 'translations_cache.dart';

/// Fetches translations for [languageCode] and caches them; falls back to
/// the last cached payload for that language if the network call fails
/// (same offline-start rule as FR-002's `loadBootstrap`), rethrowing only
/// when there's no cache either.
Future<Map<String, dynamic>> loadTranslations({
  required String languageCode,
  required TranslationsApi api,
  required TranslationsCache cache,
}) async {
  try {
    final namespaces = await api.fetchTranslations(languageCode);
    await cache.save(languageCode, namespaces);
    return namespaces;
  } catch (error) {
    final cached = cache.load(languageCode);
    if (cached != null) return cached;
    rethrow;
  }
}
