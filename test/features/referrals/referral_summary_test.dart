import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/referrals/data/models/referral_summary.dart';

Map<String, dynamic> _json() => {
      'code': 'ALICE12',
      'is_enabled': true,
      'events': {
        'JOINING': {'referrer': '1.00', 'referred': '1.00', 'enabled': true},
        'FIRST_PURCHASE': {
          'referrer': '2.00',
          'referred': '0.00',
          'enabled': true
        },
        'NEW_MERCHANT': {
          'referrer': '10.00',
          'referred': '0.00',
          'enabled': true
        },
      },
      'promo_balance': '2.00',
      'total_earned': '3.00',
      'referred_count': 2,
      'referred': [
        {
          'username': 'carol',
          'joined_at': '2026-11-01T00:00:00Z',
          'role': 'USER'
        },
      ],
      'rewards': [
        {
          'event': 'JOINING',
          'referred_username': 'carol',
          'amount': '1.00',
          'status': 'GRANTED',
          'created_at': '2026-11-01T00:00:00Z',
        },
      ],
      'currency': 'EUR',
      'share_url': 'https://triptel.co/auth/register?ref=ALICE12',
      'can_claim': true,
      'referred_by': null,
    };

void main() {
  test(
      'ReferralSummary.fromJson parses the documented GET /referrals/me '
      'response (API.md section 8)', () {
    final summary = ReferralSummary.fromJson(_json());

    expect(summary.code, 'ALICE12');
    expect(summary.isEnabled, isTrue);
    expect(summary.promoBalance.eurCents, 200);
    expect(summary.totalEarned.eurCents, 300);
    expect(summary.referredCount, 2);
    expect(summary.shareUrl, 'https://triptel.co/auth/register?ref=ALICE12');
    expect(summary.canClaim, isTrue);
    expect(summary.referredBy, isNull);
    expect(summary.referred, hasLength(1));
    expect(summary.referred.first.username, 'carol');
    expect(summary.rewards, hasLength(1));
    expect(summary.rewards.first.amount.eurCents, 100);
  });

  test('NEW_MERCHANT is a merchant-only event and is filtered out', () {
    final summary = ReferralSummary.fromJson(_json());

    expect(summary.events.containsKey('NEW_MERCHANT'), isFalse);
    expect(summary.events.keys, containsAll(['JOINING', 'FIRST_PURCHASE']));
    expect(summary.events['JOINING']!.referrer.eurCents, 100);
    expect(summary.events['FIRST_PURCHASE']!.referrer.eurCents, 200);
  });
}
