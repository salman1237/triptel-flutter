import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/bootstrap/application/bootstrap_providers.dart';
import '../storage/shared_prefs_provider.dart';
import 'language_preference.dart';
import 'translations_api.dart';
import 'translations_cache.dart';
import 'translations_loader.dart';

const _prefsKey = 'language.selected';

final translationsApiProvider = Provider<TranslationsApi>(
  (ref) => TranslationsApiImpl(ref.watch(apiClientProvider)),
);

final translationsCacheProvider =
    FutureProvider<TranslationsCache>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return TranslationsCache(prefs);
});

class LanguagePreferenceNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final bootstrap = await ref.watch(bootstrapProvider.future);
    return resolveInitialLanguage(
      storedCode: prefs.getString(_prefsKey),
      available: bootstrap.languages,
    );
  }

  /// Persists locally; same auth-sync follow-up note as FR-005's currency
  /// preference (there's no signed-in preferences endpoint call here yet).
  Future<void> select(String languageCode) async {
    state = AsyncData(languageCode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_prefsKey, languageCode);
  }
}

final languagePreferenceProvider =
    AsyncNotifierProvider<LanguagePreferenceNotifier, String>(
  LanguagePreferenceNotifier.new,
);

/// Loads (and caches) the translations for the selected language.
final translationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final code = await ref.watch(languagePreferenceProvider.future);
  final cache = await ref.watch(translationsCacheProvider.future);
  return loadTranslations(
      languageCode: code,
      api: ref.watch(translationsApiProvider),
      cache: cache);
});

/// Whether the selected language renders right-to-left.
final isRtlProvider = FutureProvider<bool>((ref) async {
  final code = await ref.watch(languagePreferenceProvider.future);
  final bootstrap = await ref.watch(bootstrapProvider.future);
  return isRtlLanguage(code, bootstrap.languages);
});
