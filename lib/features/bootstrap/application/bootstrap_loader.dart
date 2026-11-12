import '../data/bootstrap_api.dart';
import '../data/bootstrap_cache.dart';
import '../data/models/bootstrap_data.dart';
import '../data/models/currency_rate.dart';
import '../data/models/language.dart';
import '../data/models/public_settings.dart';

/// FR-002's core rule, kept in plain Dart so it's unit-testable without a
/// widget tree (Architecture.md): fetch fresh bootstrap data and cache it;
/// if the network call fails, fall back to the last cached response so the
/// app can still start offline. Only rethrows when there is no cache either.
Future<BootstrapData> loadBootstrap(
    {required BootstrapApi api, required BootstrapCache cache}) async {
  try {
    final results = await Future.wait<Object>([
      api.fetchPublicSettings(),
      api.fetchRates(),
      api.fetchLanguages(),
    ]);
    final data = BootstrapData(
      settings: results[0] as PublicSettings,
      rates: results[1] as List<CurrencyRate>,
      languages: results[2] as List<Language>,
      fromCache: false,
    );
    await cache.save(data);
    return data;
  } catch (error) {
    final cached = cache.load();
    if (cached != null) return cached;
    rethrow;
  }
}
