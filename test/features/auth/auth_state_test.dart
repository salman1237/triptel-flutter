import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';

const _token = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: false,
);

void main() {
  group('postAuthRoute', () {
    test('goes to /set-password when must_change_password is true', () {
      final state =
          AuthAuthenticated(_token.copyWith(mustChangePassword: true));
      expect(postAuthRoute(state), '/set-password');
    });

    test('goes to /home when must_change_password is false', () {
      final state = AuthAuthenticated(_token);
      expect(postAuthRoute(state), '/home');
    });

    test('goes to /home when unauthenticated (defensive default)', () {
      expect(postAuthRoute(const AuthUnauthenticated()), '/home');
    });

    test('goes to /suspended when suspended (FR-109)', () {
      expect(postAuthRoute(const AuthSuspended()), '/suspended');
    });
  });
}
