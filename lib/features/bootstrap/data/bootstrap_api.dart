import '../../../core/network/api_client.dart';
import 'models/currency_rate.dart';
import 'models/language.dart';
import 'models/public_settings.dart';

/// The bootstrap endpoints (API.md §1). Abstracted so application-layer logic
/// can be unit-tested against a fake, per Architecture.md's layering rule.
abstract class BootstrapApi {
  Future<PublicSettings> fetchPublicSettings();
  Future<List<CurrencyRate>> fetchRates();
  Future<List<Language>> fetchLanguages();
}

class BootstrapApiImpl implements BootstrapApi {
  BootstrapApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<PublicSettings> fetchPublicSettings() async {
    final data = await _client.get('/settings/public');
    return PublicSettings.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<CurrencyRate>> fetchRates() async {
    final data = await _client.get('/settings/rates');
    return (data as List)
        .map((e) => CurrencyRate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Language>> fetchLanguages() async {
    final data = await _client.get('/settings/languages');
    return (data as List)
        .map((e) => Language.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
