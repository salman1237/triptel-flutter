import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/bootstrap_data.dart';
import 'models/currency_rate.dart';
import 'models/language.dart';
import 'models/public_settings.dart';

/// Caches the last good bootstrap response so the app can start offline
/// (FR-002). Lives in `shared_preferences`, never in secure storage.
class BootstrapCache {
  BootstrapCache(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'bootstrap.settings';
  static const _ratesKey = 'bootstrap.rates';
  static const _languagesKey = 'bootstrap.languages';

  Future<void> save(BootstrapData data) async {
    await _prefs.setString(_settingsKey, jsonEncode(data.settings.toJson()));
    await _prefs.setString(
        _ratesKey, jsonEncode(data.rates.map((r) => r.toJson()).toList()));
    await _prefs.setString(
      _languagesKey,
      jsonEncode(data.languages.map((l) => l.toJson()).toList()),
    );
  }

  BootstrapData? load() {
    final settingsJson = _prefs.getString(_settingsKey);
    final ratesJson = _prefs.getString(_ratesKey);
    final languagesJson = _prefs.getString(_languagesKey);
    if (settingsJson == null || ratesJson == null || languagesJson == null) {
      return null;
    }

    return BootstrapData(
      settings: PublicSettings.fromJson(
          jsonDecode(settingsJson) as Map<String, dynamic>),
      rates: (jsonDecode(ratesJson) as List)
          .map((e) => CurrencyRate.fromJson(e as Map<String, dynamic>))
          .toList(),
      languages: (jsonDecode(languagesJson) as List)
          .map((e) => Language.fromJson(e as Map<String, dynamic>))
          .toList(),
      fromCache: true,
    );
  }
}
