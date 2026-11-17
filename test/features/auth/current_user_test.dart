import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';

void main() {
  test(
      'CurrentUser.fromJson parses the documented GET /auth/me response '
      '(API.md section 2)', () {
    final user = CurrentUser.fromJson(const {
      'id': 'uuid-1',
      'email': 'alice@example.com',
      'username': 'alice',
      'role': 'USER',
      'status': 'ACTIVE',
      'phone': '+8801700000000',
      'full_name': 'Alice Example',
      'is_kyc_verified': true,
      'preferred_currency': 'EUR',
      'avatar_url': 'https://example.com/a.png',
      'email_verified': true,
      'has_google': true,
      'wallets': [],
      'merchant_profile': null,
      'agent_profile': null,
    });

    expect(user.id, 'uuid-1');
    expect(user.phone, '+8801700000000');
    expect(user.fullName, 'Alice Example');
    expect(user.isKycVerified, isTrue);
    expect(user.avatarUrl, 'https://example.com/a.png');
    expect(user.emailVerified, isTrue);
    expect(user.hasGoogle, isTrue);
  });

  test('a bare-minimum response (new account) defaults the optional fields',
      () {
    final user = CurrentUser.fromJson(const {
      'id': 'uuid-2',
      'email': 'bob@example.com',
      'username': 'bob',
      'role': 'USER',
      'status': 'ACTIVE',
      'phone': null,
      'full_name': null,
      'is_kyc_verified': false,
      'avatar_url': null,
      'email_verified': false,
      'has_google': false,
    });

    expect(user.phone, isNull);
    expect(user.fullName, isNull);
    expect(user.avatarUrl, isNull);
    expect(user.isKycVerified, isFalse);
    expect(user.emailVerified, isFalse);
    expect(user.hasGoogle, isFalse);
  });
}
