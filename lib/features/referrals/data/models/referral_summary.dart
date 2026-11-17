import '../../../../core/money/money.dart';

class ReferralEvent {
  const ReferralEvent({
    required this.referrer,
    required this.referred,
    required this.enabled,
  });

  final Money referrer;
  final Money referred;
  final bool enabled;

  factory ReferralEvent.fromJson(Map<String, dynamic> json) => ReferralEvent(
        referrer: Money.parseEur(json['referrer'] as String),
        referred: Money.parseEur(json['referred'] as String),
        enabled: json['enabled'] as bool,
      );
}

class ReferredPerson {
  const ReferredPerson({
    required this.username,
    required this.joinedAt,
    required this.role,
  });

  final String username;
  final DateTime joinedAt;
  final String role;

  factory ReferredPerson.fromJson(Map<String, dynamic> json) => ReferredPerson(
        username: json['username'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        role: json['role'] as String,
      );
}

class ReferralReward {
  const ReferralReward({
    required this.event,
    required this.referredUsername,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String event; // JOINING | FIRST_PURCHASE | NEW_MERCHANT
  final String referredUsername;
  final Money amount;
  final String status; // GRANTED | ... (API.md doesn't enumerate further)
  final DateTime createdAt;

  factory ReferralReward.fromJson(Map<String, dynamic> json) => ReferralReward(
        event: json['event'] as String,
        referredUsername: json['referred_username'] as String,
        amount: Money.parseEur(json['amount'] as String),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// `GET /referrals/me` response (API.md §8). `NEW_MERCHANT` is a
/// merchant-only event and hidden in this (customer) app -- filtered out
/// of [events] here so presentation code never has to remember to skip it.
class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.isEnabled,
    required this.events,
    required this.promoBalance,
    required this.totalEarned,
    required this.referredCount,
    required this.referred,
    required this.rewards,
    required this.shareUrl,
    required this.canClaim,
    this.referredBy,
  });

  final String code;
  final bool isEnabled;
  final Map<String, ReferralEvent> events;
  final Money promoBalance;
  final Money totalEarned;
  final int referredCount;
  final List<ReferredPerson> referred;
  final List<ReferralReward> rewards;
  final String shareUrl;
  final bool canClaim;
  final String? referredBy;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as Map<String, dynamic>;
    return ReferralSummary(
      code: json['code'] as String,
      isEnabled: json['is_enabled'] as bool,
      events: {
        for (final entry in rawEvents.entries)
          if (entry.key != 'NEW_MERCHANT')
            entry.key:
                ReferralEvent.fromJson(entry.value as Map<String, dynamic>),
      },
      promoBalance: Money.parseEur(json['promo_balance'] as String),
      totalEarned: Money.parseEur(json['total_earned'] as String),
      referredCount: json['referred_count'] as int,
      referred: (json['referred'] as List)
          .map((r) => ReferredPerson.fromJson(r as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List)
          .map((r) => ReferralReward.fromJson(r as Map<String, dynamic>))
          .toList(),
      shareUrl: json['share_url'] as String,
      canClaim: json['can_claim'] as bool,
      referredBy: json['referred_by'] as String?,
    );
  }
}
