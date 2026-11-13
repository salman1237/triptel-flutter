import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/catalog_api.dart';
import '../data/models/country.dart';

final catalogApiProvider =
    Provider<CatalogApi>((ref) => CatalogApiImpl(ref.watch(apiClientProvider)));

/// FR-201's popular-destinations list, cached for the app session like
/// FR-950's esimVerdictProvider.
final popularCountriesProvider = FutureProvider<List<Country>>((ref) {
  return ref.watch(catalogApiProvider).getCountries(popularOnly: true);
});
