import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_store_provider.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/auth_api.dart';
import '../data/google_auth_service.dart';
import '../data/models/auth_token.dart';
import 'auth_state.dart';

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApiImpl(ref.watch(apiClientProvider)));

final googleAuthServiceProvider =
    Provider<GoogleAuthService>((ref) => GoogleAuthServiceImpl());

/// FR-101/102/105/107/108's session state.
class AuthNotifier extends AsyncNotifier<AuthState> {
  /// FR-107: a token already in secure storage (from a previous app run) is
  /// restored via `GET /auth/me`, which doesn't return `must_change_password`
  /// (API.md §2) — that flag is read from secure storage instead. A 401
  /// means the token no longer works, so it's cleared and the app falls
  /// back to signed-out; any other failure (e.g. network down) propagates
  /// as an `AsyncError`, which the UI already treats like unauthenticated.
  @override
  Future<AuthState> build() async {
    final secureStore = ref.watch(secureStoreProvider);
    final accessToken = await secureStore.readToken();
    if (accessToken == null) return const AuthUnauthenticated();

    try {
      final user = await ref.read(authApiProvider).fetchCurrentUser();
      final mustChangePassword = await secureStore.readMustChangePassword();
      return AuthAuthenticated(AuthToken(
        accessToken: accessToken,
        tokenType: 'bearer',
        role: user.role,
        userId: user.id,
        username: user.username,
        mustChangePassword: mustChangePassword,
      ));
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await secureStore.clear();
        return const AuthUnauthenticated();
      }
      rethrow;
    }
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

  /// `credential` is the Google ID token obtained with `serverClientId`.
  /// Google sign-ups carry no referral code — FR-802 (claim a referrer
  /// after the fact) is the intended follow-up, not built yet.
  Future<void> loginWithGoogle({required String credential}) async {
    final token =
        await ref.read(authApiProvider).loginWithGoogle(credential: credential);
    await ref.read(secureStoreProvider).saveToken(token.accessToken,
        mustChangePassword: token.mustChangePassword);
    state = AsyncData(AuthAuthenticated(token));
  }

  /// FR-105: clears `must_change_password` both server-side (via the API
  /// call succeeding) and in local state/storage, without starting a new
  /// session — the user stays signed in with the same access token.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref.read(authApiProvider).changePassword(
        currentPassword: currentPassword, newPassword: newPassword);

    final current = state.value;
    if (current is AuthAuthenticated) {
      final updatedToken = current.token.copyWith(mustChangePassword: false);
      await ref
          .read(secureStoreProvider)
          .saveToken(updatedToken.accessToken, mustChangePassword: false);
      state = AsyncData(AuthAuthenticated(updatedToken));
    }
  }

  Future<void> logout() async {
    await ref.read(secureStoreProvider).clear();
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
