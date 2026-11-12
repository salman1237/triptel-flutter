/// `Token` response shape from `/auth/register`, `/auth/login`,
/// `/auth/google` (API.md §2). `must_change_password` only ever comes from
/// here — `GET /auth/me` never returns it.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.role,
    required this.userId,
    required this.username,
    required this.mustChangePassword,
  });

  final String accessToken;
  final String tokenType;
  final String role;
  final String userId;
  final String username;
  final bool mustChangePassword;

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
        role: json['role'] as String? ?? 'USER',
        userId: json['user_id'] as String,
        username: json['username'] as String,
        mustChangePassword: json['must_change_password'] as bool? ?? false,
      );
}
