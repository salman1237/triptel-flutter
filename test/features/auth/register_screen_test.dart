import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/presentation/register_screen.dart';
import 'secure_storage_test_mock.dart';

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
  }) async {
    if (error != null) throw error!;
    return const AuthToken(
      accessToken: 'jwt-abc',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-1',
      username: 'alice',
      mustChangePassword: false,
    );
  }

  @override
  Future<AuthToken> login(
          {required String emailOrUsername, required String password}) =>
      throw UnimplementedError();

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
    initialLocation: '/register',
    routes: [
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
    ],
  );

  return ProviderScope(
    overrides: [
      if (authApi != null) authApiProvider.overrideWithValue(authApi)
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('submits with valid fields and navigates to /home on success',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'min8chars');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets(
      'shows a client-side error for a short password without calling the API',
      (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'short');

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets(
      'shows the backend error (e.g. duplicate email) and stays on the form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 400, message: 'Email or username already exists'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'min8chars');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Email or username already exists'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('pre-fills the referral code left by a ref link (FR-007)',
      (tester) async {
    SharedPreferences.setMockInitialValues({'referral.pendingCode': 'ABC123'});

    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    expect(find.text('ABC123'), findsOneWidget);
  });

  testWidgets('does not overwrite a referral code the user already typed',
      (tester) async {
    SharedPreferences.setMockInitialValues({'referral.pendingCode': 'ABC123'});

    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.enterText(
        find.byKey(const ValueKey('register-referral')), 'TYPED');
    await tester.pumpAndSettle();

    expect(find.text('TYPED'), findsOneWidget);
    expect(find.text('ABC123'), findsNothing);
  });
}
