import '../data/models/auth_token.dart';

/// Whether the app currently has a signed-in session.
sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.token);
  final AuthToken token;
}

/// FR-105: where to land right after a successful register/login — Set
/// Password when the backend says so, else Home. Pure so it's testable
/// without a widget tree (Architecture.md).
String postAuthRoute(AuthState state) => switch (state) {
      AuthAuthenticated(token: final token) when token.mustChangePassword =>
        '/set-password',
      _ => '/home',
    };
