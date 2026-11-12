import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store_provider.dart';
import '../../../core/storage/shared_prefs_provider.dart';
import '../data/bootstrap_api.dart';
import '../data/bootstrap_cache.dart';
import '../data/models/bootstrap_data.dart';
import 'bootstrap_loader.dart';

/// The one `dio` client in the app; its `tokenProvider` reads the JWT from
/// secure storage, so only `ApiClient` ever sees it (Rules.md).
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  return ApiClient(tokenProvider: secureStore.readToken);
});

final bootstrapApiProvider = Provider<BootstrapApi>(
  (ref) => BootstrapApiImpl(ref.watch(apiClientProvider)),
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
