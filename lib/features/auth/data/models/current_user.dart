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
    this.phone,
    this.fullName,
    this.isKycVerified = false,
    this.avatarUrl,
    this.emailVerified = false,
    this.hasGoogle = false,
  });

  final String id;
  final String email;
  final String username;
  final String role;
  final String status;
  final String? phone;
  final String? fullName;
  final bool isKycVerified;
  final String? avatarUrl;
  final bool emailVerified;
  final bool hasGoogle;

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['id'] as String,
        email: json['email'] as String,
        username: json['username'] as String,
        role: json['role'] as String? ?? 'USER',
        status: json['status'] as String? ?? 'ACTIVE',
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String?,
        isKycVerified: json['is_kyc_verified'] as bool? ?? false,
        avatarUrl: json['avatar_url'] as String?,
        emailVerified: json['email_verified'] as bool? ?? false,
        hasGoogle: json['has_google'] as bool? ?? false,
      );
}
