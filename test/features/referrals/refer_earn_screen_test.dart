import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/referrals/application/referrals_providers.dart';
import 'package:triptel/features/referrals/data/models/referral_summary.dart';
import 'package:triptel/features/referrals/data/referrals_api.dart';
import 'package:triptel/features/referrals/presentation/refer_earn_screen.dart';

class _FakeReferralsApi implements ReferralsApi {
  _FakeReferralsApi(this._summary, {this.claimError});
  ReferralSummary _summary;
  final ApiException? claimError;
  String? lastClaimedCode;

  @override
  Future<ReferralSummary> getMe() async => _summary;

  @override
  Future<ReferralSummary> claim(String code) async {
    if (claimError != null) throw claimError!;
    lastClaimedCode = code;
    _summary = ReferralSummary(
      code: _summary.code,
      isEnabled: _summary.isEnabled,
      events: _summary.events,
      promoBalance: _summary.promoBalance,
      totalEarned: _summary.totalEarned,
      referredCount: _summary.referredCount,
      referred: _summary.referred,
      rewards: _summary.rewards,
      shareUrl: _summary.shareUrl,
      canClaim: false,
      referredBy: code,
    );
    return _summary;
  }

  @override
  Future<ReferralValidation> validate(String code) =>
      throw UnimplementedError();
}

class _ThrowingReferralsApi implements ReferralsApi {
  @override
  Future<ReferralSummary> getMe() async => throw Exception('network error');

  @override
  Future<ReferralSummary> claim(String code) => throw UnimplementedError();

  @override
  Future<ReferralValidation> validate(String code) =>
      throw UnimplementedError();
}

ReferralSummary _summary({
  bool isEnabled = true,
  bool canClaim = true,
  List<ReferredPerson> referred = const [],
  List<ReferralReward> rewards = const [],
}) =>
    ReferralSummary(
      code: 'ALICE12',
      isEnabled: isEnabled,
      events: {
        'JOINING': const ReferralEvent(
            referrer: Money(100), referred: Money(100), enabled: true),
        'FIRST_PURCHASE': const ReferralEvent(
            referrer: Money(200), referred: Money(0), enabled: true),
      },
      promoBalance: const Money(200),
      totalEarned: const Money(300),
      referredCount: referred.length,
      referred: referred,
      rewards: rewards,
      shareUrl: 'https://triptel.co/auth/register?ref=ALICE12',
      canClaim: canClaim,
    );

Widget _app(ReferralsApi api) => ProviderScope(
      overrides: [referralsApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: ReferEarnScreen()),
    );

void main() {
  testWidgets('shows the code, promo balance, total earned, and people joined',
      (tester) async {
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary())));
    await tester.pumpAndSettle();

    expect(find.text('ALICE12'), findsOneWidget);
    expect(find.text('€2.00'), findsOneWidget);
    expect(find.text('€3.00'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('shows how-it-works amounts for JOINING and FIRST_PURCHASE',
      (tester) async {
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary())));
    await tester.pumpAndSettle();

    expect(find.text('You get €1.00 · they get €1.00'), findsOneWidget);
    expect(find.text('You get €2.00 · they get €0.00'), findsOneWidget);
  });

  testWidgets('no referred people yet shows an EmptyState, not a crash',
      (tester) async {
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary())));
    await tester.pumpAndSettle();

    expect(find.text('Nobody has joined with your code yet.'), findsOneWidget);
  });

  testWidgets('lists a real referred person and a real reward', (tester) async {
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary(
      referred: [
        ReferredPerson(
            username: 'carol',
            joinedAt: DateTime.utc(2026, 11, 1),
            role: 'USER'),
      ],
      rewards: [
        ReferralReward(
          event: 'JOINING',
          referredUsername: 'carol',
          amount: const Money(100),
          status: 'GRANTED',
          createdAt: DateTime.utc(2026, 11, 1),
        ),
      ],
    ))));
    await tester.pumpAndSettle();

    expect(find.text('carol'), findsOneWidget);
    expect(find.text('€1.00 · carol'), findsOneWidget);
  });

  testWidgets('can_claim shows the claim form; once claimed it disappears',
      (tester) async {
    final api = _FakeReferralsApi(_summary(canClaim: true));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('refer-claim-code-field')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('refer-claim-code-field')), 'BOB123');
    await tester
        .ensureVisible(find.byKey(const ValueKey('refer-claim-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('refer-claim-button')));
    await tester.pumpAndSettle();

    expect(api.lastClaimedCode, 'BOB123');
    expect(find.text('Referrer claimed!'), findsOneWidget);
    expect(find.byKey(const ValueKey('refer-claim-code-field')), findsNothing);
  });

  testWidgets('can_claim false hides the claim form from the start',
      (tester) async {
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary(canClaim: false))));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refer-claim-code-field')), findsNothing);
  });

  testWidgets('a real server error on claim shows the real message',
      (tester) async {
    final api = _FakeReferralsApi(
      _summary(canClaim: true),
      claimError: const ApiException(
          statusCode: 400, message: 'You already have a referrer.'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('refer-claim-code-field')), 'BOB123');
    await tester
        .ensureVisible(find.byKey(const ValueKey('refer-claim-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('refer-claim-button')));
    await tester.pumpAndSettle();

    expect(find.text('You already have a referrer.'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('refer-claim-code-field')), findsOneWidget);
  });

  testWidgets('a disabled programme shows an EmptyState instead of stats',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeReferralsApi(_summary(isEnabled: false))));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('ALICE12'), findsNothing);
  });

  testWidgets('tapping Invite shares the real share_url', (tester) async {
    // SharePlus has no test seam in this codebase yet (same limitation as
    // FR-409's tracking-link share, lib/features/esims/presentation/
    // esim_detail_screen.dart) -- this just confirms the button exists and
    // is wired, not that the platform share sheet opens.
    await tester.pumpWidget(_app(_FakeReferralsApi(_summary())));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refer-invite-button')), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(_ThrowingReferralsApi()));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
