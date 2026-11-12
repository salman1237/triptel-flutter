import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/account/presentation/account_screen.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

Widget _testApp(AuthState state) {
  final router = GoRouter(
    initialLocation: '/account',
    routes: [
      GoRoute(
          path: '/account', builder: (context, state) => const AccountScreen()),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const Text('set-password-placeholder'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(state))
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

const _tokenNeedsChange = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: true,
);

const _tokenOk = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: false,
);

void main() {
  testWidgets('shows the set-password prompt when must_change_password is true',
      (tester) async {
    await tester
        .pumpWidget(_testApp(const AuthAuthenticated(_tokenNeedsChange)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('must-change-password-prompt')),
        findsOneWidget);

    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();
    expect(find.text('set-password-placeholder'), findsOneWidget);
  });

  testWidgets('hides the prompt once must_change_password is false',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('must-change-password-prompt')),
        findsNothing);
    expect(find.text('Set password'), findsNothing);
  });
}
