import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches the last good translations response per language so a switch (or a
/// relaunch) can start offline, same pattern as FR-002's `BootstrapCache`.
class TranslationsCache {
  TranslationsCache(this._prefs);

  final SharedPreferences _prefs;

  String _key(String languageCode) => 'translations.$languageCode';

  Future<void> save(String languageCode, Map<String, dynamic> namespaces) =>
      _prefs.setString(_key(languageCode), jsonEncode(namespaces));

  Map<String, dynamic>? load(String languageCode) {
    final json = _prefs.getString(_key(languageCode));
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
