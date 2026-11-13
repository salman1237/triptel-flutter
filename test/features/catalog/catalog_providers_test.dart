import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';

class _FakeCatalogApi implements CatalogApi {
  _FakeCatalogApi({this.error});
  final Object? error;
  String? lastSearch;
  bool? lastPopularOnly;

  @override
  Future<List<Country>> getCountries({
    String? search,
    bool popularOnly = false,
  }) async {
    lastSearch = search;
    lastPopularOnly = popularOnly;
    if (error != null) throw error!;
    return const [
      Country(
          id: 107, iso2: 'JP', nameEn: 'Japan', isActive: true, slug: 'japan'),
    ];
  }
}

void main() {
  test('popularCountriesProvider requests popularOnly: true', () async {
    final fake = _FakeCatalogApi();
    final container = ProviderContainer(
      overrides: [catalogApiProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final countries = await container.read(popularCountriesProvider.future);

    expect(fake.lastPopularOnly, true);
    expect(countries, hasLength(1));
    expect(countries.first.nameEn, 'Japan');
  });

  test('popularCountriesProvider propagates errors as AsyncError', () async {
    final fake = _FakeCatalogApi(error: Exception('network down'));
    final container = ProviderContainer(
      overrides: [catalogApiProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(popularCountriesProvider.future),
      throwsException,
    );
  });
}
