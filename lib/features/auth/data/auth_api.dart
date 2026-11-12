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
}
