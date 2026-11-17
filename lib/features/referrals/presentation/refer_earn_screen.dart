import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/referrals_providers.dart';
import '../data/models/referral_summary.dart';

const _eventLabels = {
  'JOINING': 'When a friend joins',
  'FIRST_PURCHASE': 'When they make their first purchase',
};

/// FR-801: refer & earn, Eskimo "Free data" card pattern (docs/design-
/// reference/10-rewards-referral.png) re-skinned in Triptel tokens. Code +
/// Invite (shares `share_url`), stats (promo balance/total earned/people
/// joined), how it works (per-event referrer/referred amounts -- API.md
/// §8's `NEW_MERCHANT` event is filtered out in the model, a merchant-only
/// feature out of scope for this customer app), referred people and
/// rewards lists. FR-802 (claim a referrer) is a separate, not-yet-built
/// feature -- no claim UI here even though `ReferralsApi.claim` already
/// exists for it to use when built.
class ReferEarnScreen extends ConsumerWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(referralSummaryProvider);

    return TriptelScaffold(
      key: const ValueKey('refer-earn-screen'),
      appBar: AppBar(title: const Text('Refer & earn')),
      body: switch (summaryAsync) {
        AsyncData(:final value) => !value.isEnabled
            ? const Center(
                child: EmptyState(
                  icon: Icons.card_giftcard_outlined,
                  message: 'The referral programme isn\'t available right '
                      'now.',
                ),
              )
            : _ReferEarnBody(summary: value),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your referral details.",
              onRetry: () => ref.invalidate(referralSummaryProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReferEarnBody extends StatelessWidget {
  const _ReferEarnBody({required this.summary});

  final ReferralSummary summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BalanceCard(
            title: 'Promo balance',
            amountText: '€${summary.promoBalance.eurValue.toStringAsFixed(2)}',
            stats: [
              (
                'Total earned',
                '€${summary.totalEarned.eurValue.toStringAsFixed(2)}'
              ),
              ('People joined', '${summary.referredCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: const ValueKey('refer-code-chip'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(summary.code,
                      textAlign: TextAlign.center,
                      style: AppTypography.title()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                // PillButton's primary/secondary variants set a
                // Size.fromHeight minimumSize (infinite width) regardless
                // of `fullWidth` -- fine standalone, but inside a Row next
                // to an Expanded it needs an explicit bound.
                width: 110,
                child: PillButton(
                  key: const ValueKey('refer-invite-button'),
                  label: 'Invite',
                  fullWidth: false,
                  onPressed: () => SharePlus.instance
                      .share(ShareParams(text: summary.shareUrl)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('How it works', style: AppTypography.title()),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              for (final entry in summary.events.entries)
                ListRow(
                  icon: Icons.card_giftcard_outlined,
                  title: _eventLabels[entry.key] ?? entry.key,
                  subtitle: 'You get '
                      '€${entry.value.referrer.eurValue.toStringAsFixed(2)}'
                      ' · they get '
                      '€${entry.value.referred.eurValue.toStringAsFixed(2)}',
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Referred people (${summary.referred.length})',
              style: AppTypography.title()),
          const SizedBox(height: 8),
          summary.referred.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: EmptyState(
                    icon: Icons.people_outline,
                    message: 'Nobody has joined with your code yet.',
                  ),
                )
              : ListGroup(
                  children: [
                    for (final person in summary.referred)
                      ListRow(
                        icon: Icons.person_outline,
                        title: person.username,
                        subtitle: DateFormat.yMMMd()
                            .format(person.joinedAt.toLocal()),
                      ),
                  ],
                ),
          const SizedBox(height: 24),
          Text('Rewards', style: AppTypography.title()),
          const SizedBox(height: 8),
          summary.rewards.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No rewards yet.',
                  ),
                )
              : ListGroup(
                  children: [
                    for (final reward in summary.rewards)
                      ListRow(
                        icon: Icons.stars_outlined,
                        title: '€${reward.amount.eurValue.toStringAsFixed(2)} '
                            '· ${reward.referredUsername}',
                        subtitle: '${reward.status} · '
                            '${DateFormat.yMMMd().format(reward.createdAt.toLocal())}',
                      ),
                  ],
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
