import '../network/api_client.dart';

/// `GET /settings/translations/{language_code}` (API.md §1). Missing keys are
/// already back-filled with English server-side.
abstract class TranslationsApi {
  Future<Map<String, dynamic>> fetchTranslations(String languageCode);
}

class TranslationsApiImpl implements TranslationsApi {
  TranslationsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> fetchTranslations(String languageCode) async {
    final data = await _client.get('/settings/translations/$languageCode');
    return (data as Map<String, dynamic>)['namespaces']
            as Map<String, dynamic>? ??
        {};
  }
}
