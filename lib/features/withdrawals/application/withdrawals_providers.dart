import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/payout_account.dart';
import '../data/models/withdrawal.dart';
import '../data/models/withdrawal_config.dart';
import '../data/withdrawals_api.dart';

final withdrawalsApiProvider = Provider<WithdrawalsApi>(
  (ref) => WithdrawalsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-701: the signed-in user's saved payout accounts.
final payoutAccountsProvider = FutureProvider<List<PayoutAccount>>((ref) {
  return ref.watch(withdrawalsApiProvider).getAccounts();
});

/// FR-702: limits, fee terms, and eligibility blockers for the withdraw page.
final withdrawalConfigProvider = FutureProvider<WithdrawalConfig>((ref) {
  return ref.watch(withdrawalsApiProvider).getConfig();
});

/// FR-703: the signed-in user's withdrawal history, newest first.
final withdrawalsProvider = FutureProvider<List<Withdrawal>>((ref) {
  return ref.watch(withdrawalsApiProvider).getWithdrawals();
});
