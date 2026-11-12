import '../../../core/network/api_client.dart';
import 'models/auth_token.dart';

/// Auth endpoints this app uses (API.md §2). Abstracted so application-layer
/// logic (AuthNotifier) can be unit-tested against a fake.
abstract class AuthApi {
  Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  });

  Future<AuthToken> login(
      {required String emailOrUsername, required String password});

  /// `credential` is the Google ID token, requested with `serverClientId` =
  /// `/settings/public.google_client_id` (API.md §2 — the **web** client id;
  /// an Android OAuth client registered for `co.triptel.app` + its signing
  /// SHA-1 must also exist in Google Cloud Console or the native sign-in
  /// flow never completes, even though that client id isn't sent here).
  Future<AuthToken> loginWithGoogle({required String credential});
}

class AuthApiImpl implements AuthApi {
  AuthApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  }) async {
    final data = await _client.post(
      '/auth/register',
      data: {
        'email': email,
        'username': username,
        'password': password,
        'phone': phone,
        'full_name': fullName,
        'referral_code': referralCode,
      },
    );
    return AuthToken.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AuthToken> login(
      {required String emailOrUsername, required String password}) async {
    final data = await _client.post(
      '/auth/login',
      data: {'email': emailOrUsername, 'password': password},
    );
    return AuthToken.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) async {
    final data =
        await _client.post('/auth/google', data: {'credential': credential});
    return AuthToken.fromJson(data as Map<String, dynamic>);
  }
}
