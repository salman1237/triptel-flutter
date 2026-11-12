import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/presentation/login_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'secure_storage_test_mock.dart';

final _noGoogleBootstrap = BootstrapData(
  settings: const PublicSettings(
    platformName: 'Triptel',
    maintenanceMode: false,
    defaultCurrency: 'EUR',
  ),
  rates: const [],
  languages: const [],
  fromCache: false,
);

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.error});
  final ApiException? error;

  @override
  Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthToken> login(
      {required String emailOrUsername, required String password}) async {
    if (error != null) throw error!;
    return AuthToken(
      accessToken: 'jwt-abc',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-1',
      username: emailOrUsername,
      mustChangePassword: false,
    );
  }

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();
}

Widget _testApp({AuthApi? authApi}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const Text('register-placeholder')),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Text('forgot-password-placeholder')),
    ],
  );

  return ProviderScope(
    overrides: [
      bootstrapProvider.overrideWith((ref) async => _noGoogleBootstrap),
      if (authApi != null) authApiProvider.overrideWithValue(authApi),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('signs in with valid credentials and navigates to /home',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'password');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets('shows a client-side error when a field is empty',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter your email/username and password'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('shows the real 401 error and stays on the form', (tester) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 401, message: 'Invalid email/username or password'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'wrong');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email/username or password'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('shows the real 403 suspended error', (tester) async {
    await tester.pumpWidget(
      _testApp(
          authApi: _FakeAuthApi(
              error: const ApiException(
                  statusCode: 403, message: 'Account suspended'))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'password');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Account suspended'), findsOneWidget);
  });

  testWidgets('navigates to /register via the secondary link', (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account instead'));
    await tester.pumpAndSettle();

    expect(find.text('register-placeholder'), findsOneWidget);
  });

  testWidgets('navigates to /forgot-password via the Forgot password? link',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-forgot-password')));
    await tester.pumpAndSettle();

    expect(find.text('forgot-password-placeholder'), findsOneWidget);
  });
}
