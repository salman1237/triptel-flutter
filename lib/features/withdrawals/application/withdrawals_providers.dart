import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/payout_account.dart';
import '../data/withdrawals_api.dart';

final withdrawalsApiProvider = Provider<WithdrawalsApi>(
  (ref) => WithdrawalsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-701: the signed-in user's saved payout accounts.
final payoutAccountsProvider = FutureProvider<List<PayoutAccount>>((ref) {
  return ref.watch(withdrawalsApiProvider).getAccounts();
});
