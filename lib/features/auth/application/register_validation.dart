/// API.md §2: "Password length isn't validated here (only on change/reset)
/// — enforce ≥ 8 client-side." Kept pure so it's unit-testable without a
/// widget tree (Architecture.md).
String? validateRegisterPassword(String password) {
  if (password.length < 8) return 'Password must be at least 8 characters';
  return null;
}

String? validateEmail(String email) {
  if (email.trim().isEmpty) return 'Email is required';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email';
  }
  return null;
}

String? validateUsername(String username) {
  if (username.trim().isEmpty) return 'Username is required';
  return null;
}
