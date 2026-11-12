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
