import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/catalog_api.dart';
import '../data/models/country.dart';
import '../data/models/destination.dart';

final catalogApiProvider =
    Provider<CatalogApi>((ref) => CatalogApiImpl(ref.watch(apiClientProvider)));

/// FR-201's popular-destinations list, cached for the app session like
/// FR-950's esimVerdictProvider.
final popularCountriesProvider = FutureProvider<List<Country>>((ref) {
  return ref.watch(catalogApiProvider).getCountries(popularOnly: true);
});

/// FR-202's full catalog (Country + Regional tabs, A-Z list), cached for the
/// app session -- the explore sheet can be opened/closed repeatedly without
/// re-fetching.
final allCountriesProvider = FutureProvider<List<Country>>((ref) {
  return ref.watch(catalogApiProvider).getCountries();
});

/// FR-203: a regional package's coverage list, keyed by iso2.
final coverageCountriesProvider =
    FutureProvider.family<List<String>, String>((ref, iso2) {
  return ref.watch(catalogApiProvider).getCoverageCountries(iso2);
});

/// FR-204: a destination's products for the plans screen, keyed by slug.
final destinationProvider =
    FutureProvider.family<Destination, String>((ref, slug) {
  return ref.watch(catalogApiProvider).getDestination(slug);
});
