import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/wallet.dart';
import '../data/wallets_api.dart';

final walletsApiProvider = Provider<WalletsApi>(
  (ref) => WalletsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-601: the signed-in user's real wallets (DEFAULT/REWARD/COMMISSION).
final myWalletsProvider = FutureProvider<List<Wallet>>((ref) {
  return ref.watch(walletsApiProvider).getMyWallets();
});
