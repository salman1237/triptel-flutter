import '../../../core/network/api_client.dart';
import 'models/country.dart';

abstract class CatalogApi {
  Future<List<Country>> getCountries(
      {String? search, bool popularOnly = false});

  /// FR-203: the covered country names for a regional package, read off its
  /// products' `coverage_countries` (API.md §3 -- identical across a
  /// regional country's products, so the first product is enough).
  Future<List<String>> getCoverageCountries(String iso2);
}

class CatalogApiImpl implements CatalogApi {
  CatalogApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Country>> getCountries({
    String? search,
    bool popularOnly = false,
  }) async {
    final response = await _client.get('/catalog/countries', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      'popular_only': popularOnly,
    });
    return (response as List)
        .map((json) => Country.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getCoverageCountries(String iso2) async {
    final response = await _client.get('/catalog/countries/$iso2/products');
    final products = response as List;
    if (products.isEmpty) return const [];
    final coverage =
        (products.first as Map<String, dynamic>)['coverage_countries'];
    if (coverage is List) return coverage.cast<String>();
    return const [];
  }
}
