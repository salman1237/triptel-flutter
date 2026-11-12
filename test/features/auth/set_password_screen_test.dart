import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'package:triptel/features/auth/presentation/set_password_screen.dart';
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
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (error != null) throw error!;
  }

  @override
  Future<CurrentUser> fetchCurrentUser() => throw UnimplementedError();
}

Widget _testApp({AuthApi? authApi}) {
  final router = GoRouter(
    initialLocation: '/set-password',
    routes: [
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
      GoRoute(
        path: '/my-esims',
        builder: (context, state) => const Text('my-esims-placeholder'),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('submits and shows a success state with a Continue button',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('set-password-current')), 'temp-pass');
    await tester.enterText(
        find.byKey(const ValueKey('set-password-new')), 'newpass123');
    await tester.tap(find.byKey(const ValueKey('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('set-password-success')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets('shows a client-side error for a short new password',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('set-password-current')), 'temp-pass');
    await tester.enterText(
        find.byKey(const ValueKey('set-password-new')), 'short');
    await tester.tap(find.byKey(const ValueKey('set-password-submit')));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.byKey(const ValueKey('set-password-success')), findsNothing);
  });

  testWidgets('shows the real backend error (e.g. wrong current password)',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 400, message: 'Wrong current password'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('set-password-current')), 'wrong');
    await tester.enterText(
        find.byKey(const ValueKey('set-password-new')), 'newpass123');
    await tester.tap(find.byKey(const ValueKey('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Wrong current password'), findsOneWidget);
    expect(find.byKey(const ValueKey('set-password-success')), findsNothing);
  });

  testWidgets(
    'the "Not now" link navigates to My eSIMs without requiring the password change (FR-105: never blocks it)',
    (tester) async {
      await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('set-password-skip')));
      await tester.pumpAndSettle();

      expect(find.text('my-esims-placeholder'), findsOneWidget);
    },
  );
}
