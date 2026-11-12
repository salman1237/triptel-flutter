import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_store_provider.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/auth_api.dart';
import 'auth_state.dart';

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApiImpl(ref.watch(apiClientProvider)));

/// FR-101/102/108's session state. FR-107 (restore a session that already
/// existed when the app launched, via `GET /auth/me`) isn't built yet — for
/// now a signed-in session only lives for the current app run, though the
/// token is still persisted to secure storage so FR-107 has something to
/// read once it exists.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthUnauthenticated();
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  }) async {
    final token = await ref.read(authApiProvider).register(
          email: email,
          username: username,
          password: password,
          phone: phone,
          fullName: fullName,
          referralCode: referralCode,
        );
    await ref.read(secureStoreProvider).saveToken(token.accessToken,
        mustChangePassword: token.mustChangePassword);
    state = AsyncData(AuthAuthenticated(token));
  }

  Future<void> login(
      {required String emailOrUsername, required String password}) async {
    final token = await ref
        .read(authApiProvider)
        .login(emailOrUsername: emailOrUsername, password: password);
    await ref.read(secureStoreProvider).saveToken(token.accessToken,
        mustChangePassword: token.mustChangePassword);
    state = AsyncData(AuthAuthenticated(token));
  }

  Future<void> logout() async {
    await ref.read(secureStoreProvider).clear();
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
