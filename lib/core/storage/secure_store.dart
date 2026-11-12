import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT + `must_change_password` live here ONLY (Rules.md) — never in
/// `shared_preferences`, logs, or widget state outside the auth provider.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth.accessToken';
  static const _mustChangeKey = 'auth.mustChangePassword';

  Future<void> saveToken(String accessToken,
      {required bool mustChangePassword}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(
        key: _mustChangeKey, value: mustChangePassword.toString());
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<bool> readMustChangePassword() async =>
      (await _storage.read(key: _mustChangeKey)) == 'true';

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _mustChangeKey);
  }
}
