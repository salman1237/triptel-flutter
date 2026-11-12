import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'package:triptel/features/auth/presentation/forgot_password_screen.dart';

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
          {required String emailOrUsername, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) async {
    if (error != null) throw error!;
  }

  @override
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();

  @override
  Future<CurrentUser> fetchCurrentUser() => throw UnimplementedError();
}

Widget _testApp({AuthApi? authApi}) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
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
  testWidgets(
      'shows a client-side error for an invalid email without calling the API',
      (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('forgot-password-email')), 'notanemail');
    await tester.tap(find.byKey(const ValueKey('forgot-password-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-password-success')), findsNothing);
  });

  testWidgets(
      'shows the generic success message and explains the web reset link', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('forgot-password-email')), 'a@b.co');
    await tester.tap(find.byKey(const ValueKey('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('forgot-password-success')), findsOneWidget);
    expect(find.textContaining('opens on the web'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-password-email')), findsNothing);
  });

  testWidgets(
      'shows the same success message even for an unknown email (no enumeration)',
      (
    tester,
  ) async {
    // API.md §2: the endpoint always returns the same generic success
    // whether or not the email exists, so the fake never throws here either.
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('forgot-password-email')),
      'unknown@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('forgot-password-success')), findsOneWidget);
  });

  testWidgets(
      'shows a real backend error (e.g. rate limited) and stays on the form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 429, message: 'Too many attempts, wait a minute'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('forgot-password-email')), 'a@b.co');
    await tester.tap(find.byKey(const ValueKey('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Too many attempts, wait a minute'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-password-success')), findsNothing);
  });
}
