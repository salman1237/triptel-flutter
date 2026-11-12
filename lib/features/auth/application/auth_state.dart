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

/// FR-109: a 403 "Account suspended" was seen (on login or on session
/// restore) — the token, if any, has already been cleared (API.md §0.1:
/// "sign out, show suspended screen").
class AuthSuspended extends AuthState {
  const AuthSuspended();
}

/// FR-105: where to land right after a successful register/login — Set
/// Password when the backend says so, else Home. Pure so it's testable
/// without a widget tree (Architecture.md).
String postAuthRoute(AuthState state) => switch (state) {
      AuthAuthenticated(token: final token) when token.mustChangePassword =>
        '/set-password',
      AuthSuspended() => '/suspended',
      _ => '/home',
    };
