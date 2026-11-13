import '../../../core/network/api_client.dart';
import 'models/country.dart';

abstract class CatalogApi {
  Future<List<Country>> getCountries(
      {String? search, bool popularOnly = false});
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
}
