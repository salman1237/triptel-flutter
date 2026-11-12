import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/storage/secure_store_provider.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'secure_storage_test_mock.dart';

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.registerError,
    this.loginMustChangePassword = false,
    this.googleError,
  });

  final ApiException? registerError;
  final bool loginMustChangePassword;
  final ApiException? googleError;

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
