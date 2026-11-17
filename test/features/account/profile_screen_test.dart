import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'package:triptel/features/account/presentation/profile_screen.dart';

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi(this._user, {this.updateError});
  CurrentUser _user;
  final ApiException? updateError;
  String? lastPhone;

  @override
  Future<CurrentUser> fetchCurrentUser() async => _user;

  @override
  Future<void> updatePhone(String phone) async {
    if (updateError != null) throw updateError!;
    lastPhone = phone;
    _user = CurrentUser(
      id: _user.id,
      email: _user.email,
      username: _user.username,
      role: _user.role,
      status: _user.status,
      phone: phone,
      fullName: _user.fullName,
      isKycVerified: _user.isKycVerified,
      avatarUrl: _user.avatarUrl,
      emailVerified: _user.emailVerified,
      hasGoogle: _user.hasGoogle,
    );
  }

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
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();
}

CurrentUser _user({
  String? phone,
  String? fullName,
  bool emailVerified = false,
  bool hasGoogle = false,
}) =>
    CurrentUser(
      id: 'u-1',
      email: 'alice@example.com',
      username: 'alice',
      role: 'USER',
      status: 'ACTIVE',
      phone: phone,
      fullName: fullName,
      emailVerified: emailVerified,
      hasGoogle: hasGoogle,
    );

Widget _app(AuthApi authApi) {
  final router = GoRouter(initialLocation: '/profile', routes: [
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/set-password',
      builder: (context, state) =>
          const Scaffold(body: Text('set-password-placeholder')),
    ),
  ]);
  return ProviderScope(
    overrides: [authApiProvider.overrideWithValue(authApi)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows the real username, email, and phone', (tester) async {
    await tester.pumpWidget(_app(_FakeAuthApi(_user(phone: '+8801700000000'))));
    await tester.pumpAndSettle();

    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('+8801700000000'), findsOneWidget);
  });

  testWidgets('shows the full name when present, username otherwise',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeAuthApi(_user(fullName: 'Alice Example'))));
    await tester.pumpAndSettle();

    expect(find.text('Alice Example'), findsOneWidget);
  });

  testWidgets(
      'email_verified true shows "Verified", false shows '
      '"Not verified"', (tester) async {
    await tester.pumpWidget(_app(_FakeAuthApi(_user(emailVerified: true))));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);

    await tester.pumpWidget(_app(_FakeAuthApi(_user(emailVerified: false))));
    await tester.pumpAndSettle();
    expect(find.text('Not verified'), findsOneWidget);
  });

  testWidgets('has_google true shows the Google-linked row, false hides it',
      (tester) async {
    await tester.pumpWidget(_app(_FakeAuthApi(_user(hasGoogle: true))));
    await tester.pumpAndSettle();
    expect(find.text('Google account linked'), findsOneWidget);

    await tester.pumpWidget(_app(_FakeAuthApi(_user(hasGoogle: false))));
    await tester.pumpAndSettle();
    expect(find.text('Google account linked'), findsNothing);
  });

  testWidgets(
      'editing and saving the phone calls the real API with the typed '
      'value and shows a confirmation', (tester) async {
    final api = _FakeAuthApi(_user());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('profile-phone-field')), '+8801900000000');
    await tester.tap(find.byKey(const ValueKey('profile-save-phone-button')));
    await tester.pumpAndSettle();

    expect(api.lastPhone, '+8801900000000');
    expect(find.text('Phone number saved.'), findsOneWidget);
  });

  testWidgets('a real server error on save shows the real message',
      (tester) async {
    final api = _FakeAuthApi(
      _user(),
      updateError:
          const ApiException(statusCode: 400, message: 'Invalid phone.'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-save-phone-button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid phone.'), findsOneWidget);
  });

  testWidgets('tapping Change password navigates to the real FR-105 screen',
      (tester) async {
    await tester.pumpWidget(_app(_FakeAuthApi(_user())));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('profile-change-password-button')));
    await tester.pumpAndSettle();

    expect(find.text('set-password-placeholder'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
