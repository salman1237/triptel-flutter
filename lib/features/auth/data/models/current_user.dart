/// `GET /auth/me` response (API.md §2). Notably does NOT include
/// `must_change_password` — only `Token` responses (login/register/google)
/// ever carry that; it must be read from secure storage on session restore.
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.status,
  });

  final String id;
  final String email;
  final String username;
  final String role;
  final String status;

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['id'] as String,
        email: json['email'] as String,
        username: json['username'] as String,
        role: json['role'] as String? ?? 'USER',
        status: json['status'] as String? ?? 'ACTIVE',
      );
}
