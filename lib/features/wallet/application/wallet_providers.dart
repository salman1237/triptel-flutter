import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/ledger_entry.dart';
import '../data/models/wallet.dart';
import '../data/wallets_api.dart';

final walletsApiProvider = Provider<WalletsApi>(
  (ref) => WalletsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-601: the signed-in user's real wallets (DEFAULT/REWARD/COMMISSION).
final myWalletsProvider = FutureProvider<List<Wallet>>((ref) {
  return ref.watch(walletsApiProvider).getMyWallets();
});

/// FR-602: the ledger filter the user picked (null = all wallet types).
final ledgerFilterProvider = StateProvider<String?>((ref) => null);

/// FR-602: transaction history, re-fetched whenever [ledgerFilterProvider]
/// changes.
final ledgerProvider = FutureProvider<List<LedgerEntry>>((ref) {
  final walletType = ref.watch(ledgerFilterProvider);
  return ref.watch(walletsApiProvider).getLedger(walletType: walletType);
});
