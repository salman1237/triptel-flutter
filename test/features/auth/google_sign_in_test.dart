import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/google_auth_service.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'package:triptel/features/auth/presentation/login_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'secure_storage_test_mock.dart';

class _FakeAuthApi implements AuthApi {
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
          {required String emailOrUsername, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();

  @override
  Future<CurrentUser> fetchCurrentUser() => throw UnimplementedError();

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) async =>
      const AuthToken(
        accessToken: 'jwt-google',
        tokenType: 'bearer',
        role: 'USER',
        userId: 'u-3',
        username: 'google-user',
        mustChangePassword: false,
      );
}

class _FakeGoogleAuthService implements GoogleAuthService {
  _FakeGoogleAuthService({this.idToken = 'fake-id-token'});
  final String? idToken;

  @override
  Future<String?> signIn({required String serverClientId}) async => idToken;
}

BootstrapData _bootstrap({String? googleClientId}) => BootstrapData(
      settings: PublicSettings(
        platformName: 'Triptel',
        maintenanceMode: false,
        defaultCurrency: 'EUR',
        googleClientId: googleClientId,
      ),
      rates: const [],
      languages: const [],
      fromCache: false,
    );

Widget _testApp(
    {required BootstrapData bootstrap, GoogleAuthService? googleAuthService}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
    ],
  );

  return ProviderScope(
    overrides: [
      bootstrapProvider.overrideWith((ref) async => bootstrap),
      authApiProvider.overrideWithValue(_FakeAuthApi()),
      if (googleAuthService != null)
        googleAuthServiceProvider.overrideWithValue(googleAuthService),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('hides the Google button when no google_client_id is configured',
      (tester) async {
    await tester
        .pumpWidget(_testApp(bootstrap: _bootstrap(googleClientId: null)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-google')), findsNothing);
  });

  testWidgets('shows the Google button and signs in on success',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        bootstrap: _bootstrap(googleClientId: 'web-client-id'),
        googleAuthService: _FakeGoogleAuthService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-google')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login-google')));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets('does nothing when the user cancels the Google picker',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        bootstrap: _bootstrap(googleClientId: 'web-client-id'),
        googleAuthService: _FakeGoogleAuthService(idToken: null),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-google')));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsNothing);
    expect(find.byKey(const ValueKey('login-google')), findsOneWidget);
  });
}
