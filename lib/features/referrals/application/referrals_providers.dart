import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/referral_summary.dart';
import '../data/referrals_api.dart';

final referralsApiProvider = Provider<ReferralsApi>(
  (ref) => ReferralsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-801: the signed-in user's referral code, stats, and lists.
final referralSummaryProvider = FutureProvider<ReferralSummary>((ref) {
  return ref.watch(referralsApiProvider).getMe();
});
