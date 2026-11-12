import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/storage/secure_store.dart';
import 'package:triptel/core/storage/secure_store_provider.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'secure_storage_test_mock.dart';

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.registerError,
    this.loginMustChangePassword = false,
    this.googleError,
    this.changePasswordError,
    this.currentUser,
    this.currentUserError,
  });

  final ApiException? registerError;
  final bool loginMustChangePassword;
  final ApiException? googleError;
  final ApiException? changePasswordError;
  final CurrentUser? currentUser;
  final ApiException? currentUserError;

  static const token = AuthToken(
    accessToken: 'jwt-abc',
    tokenType: 'bearer',
    role: 'USER',
    userId: 'u-1',
    username: 'alice',
    mustChangePassword: false,
  );

  @override
  Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  }) async {
    if (registerError != null) throw registerError!;
    return token;
  }

  @override
  Future<AuthToken> login(
      {required String emailOrUsername, required String password}) async {
    return AuthToken(
      accessToken: 'jwt-login',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-2',
      username: emailOrUsername,
      mustChangePassword: loginMustChangePassword,
    );
  }

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) async {
    if (googleError != null) throw googleError!;
    return const AuthToken(
      accessToken: 'jwt-google',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-3',
      username: 'google-user',
      mustChangePassword: false,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<CurrentUser> fetchCurrentUser() async {
    if (currentUserError != null) throw currentUserError!;
    return currentUser ??
        const CurrentUser(
          id: 'u-1',
          email: 'alice@example.com',
          username: 'alice',
          role: 'USER',
          status: 'ACTIVE',
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts unauthenticated', () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(_FakeAuthApi())],
    );
    addTearDown(container.dispose);

    expect(await container.read(authNotifierProvider.future),
        isA<AuthUnauthenticated>());
  });

  test('restores the session from a stored token via GET /auth/me (FR-107)',
      () async {
    installFakeSecureStorage();
    await SecureStore().saveToken('stored-jwt', mustChangePassword: true);
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            currentUser: const CurrentUser(
              id: 'u-9',
              email: 'x@y.co',
              username: 'restored',
              role: 'USER',
              status: 'ACTIVE',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(authNotifierProvider.future);
    expect(state, isA<AuthAuthenticated>());
    final token = (state as AuthAuthenticated).token;
    expect(token.accessToken, 'stored-jwt');
    expect(token.username, 'restored');
    // must_change_password only ever comes from Token responses, never
    // GET /auth/me (API.md §2) -- it has to come from secure storage.
    expect(token.mustChangePassword, isTrue);
  });

  test('clears the session on a 401 from GET /auth/me (stale token)', () async {
    installFakeSecureStorage();
    await SecureStore().saveToken('stale-jwt', mustChangePassword: false);
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            currentUserError: const ApiException(
              statusCode: 401,
              message: 'Could not validate authentication credentials',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(authNotifierProvider.future);
    expect(state, isA<AuthUnauthenticated>());
    final store = container.read(secureStoreProvider);
    expect(await store.readToken(), isNull);
  });

  test('a non-401 failure while restoring does not clear the stored token',
      () async {
    installFakeSecureStorage();
    await SecureStore()
        .saveToken('flaky-network-jwt', mustChangePassword: false);
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            currentUserError: const ApiException(
                statusCode: 503, message: 'Service unavailable'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(authNotifierProvider.future),
      throwsA(isA<ApiException>()),
    );

    final store = container.read(secureStoreProvider);
    expect(await store.readToken(), 'flaky-network-jwt',
        reason: 'only a 401 should clear the token, not a transient failure');
  });

  test('register() signs the user in and persists the token', () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(_FakeAuthApi())],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container.read(authNotifierProvider.notifier).register(
          email: 'a@b.co',
          username: 'alice',
          password: 'min8chars',
        );

    final state = container.read(authNotifierProvider).value;
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).token.username, 'alice');
  });

  test(
      'register() surfaces an ApiException (e.g. 400 email exists) without signing in',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            registerError: const ApiException(
                statusCode: 400, message: 'Email or username already exists'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);

    await expectLater(
      container.read(authNotifierProvider.notifier).register(
            email: 'a@b.co',
            username: 'alice',
            password: 'min8chars',
          ),
      throwsA(isA<ApiException>()),
    );

    expect(
        container.read(authNotifierProvider).value, isA<AuthUnauthenticated>());
  });

  test('login() signs the user in', () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(_FakeAuthApi())],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container
        .read(authNotifierProvider.notifier)
        .login(emailOrUsername: 'salman2033', password: 'whatever');

    final state = container.read(authNotifierProvider).value;
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).token.username, 'salman2033');
  });

  test('login() persists must_change_password to secure storage (API.md §2)',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authApiProvider
            .overrideWithValue(_FakeAuthApi(loginMustChangePassword: true)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container
        .read(authNotifierProvider.notifier)
        .login(emailOrUsername: 'salman2033', password: 'whatever');

    final store = container.read(secureStoreProvider);
    expect(await store.readToken(), 'jwt-login');
    expect(await store.readMustChangePassword(), isTrue);
  });

  test('loginWithGoogle() signs the user in with the credential exchange',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(_FakeAuthApi())],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container
        .read(authNotifierProvider.notifier)
        .loginWithGoogle(credential: 'fake-id-token');

    final state = container.read(authNotifierProvider).value;
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).token.username, 'google-user');
  });

  test(
      'loginWithGoogle() surfaces an ApiException (e.g. 409 linked to a different account)',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            googleError: const ApiException(
                statusCode: 409,
                message: 'Email linked to a different Google account'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);

    await expectLater(
      container
          .read(authNotifierProvider.notifier)
          .loginWithGoogle(credential: 'fake-id-token'),
      throwsA(isA<ApiException>()),
    );

    expect(
        container.read(authNotifierProvider).value, isA<AuthUnauthenticated>());
  });

  test(
      'changePassword() clears must_change_password in state and secure storage',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authApiProvider
            .overrideWithValue(_FakeAuthApi(loginMustChangePassword: true)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container
        .read(authNotifierProvider.notifier)
        .login(emailOrUsername: 'salman2033', password: 'temp-pass');
    var state = container.read(authNotifierProvider).value as AuthAuthenticated;
    expect(state.token.mustChangePassword, isTrue);

    await container.read(authNotifierProvider.notifier).changePassword(
        currentPassword: 'temp-pass', newPassword: 'newpass123');

    state = container.read(authNotifierProvider).value as AuthAuthenticated;
    expect(state.token.mustChangePassword, isFalse);
    expect(state.token.accessToken, 'jwt-login');
    final store = container.read(secureStoreProvider);
    expect(await store.readMustChangePassword(), isFalse);
  });

  test(
      'changePassword() surfaces an ApiException (e.g. 400 wrong current password)',
      () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(
          _FakeAuthApi(
            loginMustChangePassword: true,
            changePasswordError: const ApiException(
                statusCode: 400, message: 'Wrong current password'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container
        .read(authNotifierProvider.notifier)
        .login(emailOrUsername: 'salman2033', password: 'temp-pass');

    await expectLater(
      container
          .read(authNotifierProvider.notifier)
          .changePassword(currentPassword: 'wrong', newPassword: 'newpass123'),
      throwsA(isA<ApiException>()),
    );

    final state =
        container.read(authNotifierProvider).value as AuthAuthenticated;
    expect(state.token.mustChangePassword, isTrue,
        reason: 'flag stays set when the call fails');
  });

  test('logout() clears the session', () async {
    installFakeSecureStorage();
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(_FakeAuthApi())],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await container.read(authNotifierProvider.notifier).register(
          email: 'a@b.co',
          username: 'alice',
          password: 'min8chars',
        );
    expect(
        container.read(authNotifierProvider).value, isA<AuthAuthenticated>());

    await container.read(authNotifierProvider.notifier).logout();

    expect(
        container.read(authNotifierProvider).value, isA<AuthUnauthenticated>());
  });
}
