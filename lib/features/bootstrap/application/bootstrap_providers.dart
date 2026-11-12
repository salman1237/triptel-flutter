import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../data/bootstrap_api.dart';
import '../data/bootstrap_cache.dart';
import '../data/models/bootstrap_data.dart';
import 'bootstrap_loader.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final bootstrapApiProvider = Provider<BootstrapApi>(
  (ref) => BootstrapApiImpl(ref.watch(apiClientProvider)),
);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final bootstrapCacheProvider = FutureProvider<BootstrapCache>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return BootstrapCache(prefs);
});

/// Loads once per app run; the maintenance gate and splash watch this.
final bootstrapProvider = FutureProvider<BootstrapData>((ref) async {
  final cache = await ref.watch(bootstrapCacheProvider.future);
  return loadBootstrap(api: ref.watch(bootstrapApiProvider), cache: cache);
});
