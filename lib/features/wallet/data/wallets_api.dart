import '../../../core/network/api_client.dart';
import 'models/ledger_entry.dart';
import 'models/wallet.dart';

abstract class WalletsApi {
  /// `GET /wallets/my-wallets` (auth).
  Future<List<Wallet>> getMyWallets();

  /// `GET /wallets/ledger` (auth). `walletType` filters server-side; the
  /// response rows themselves carry no `wallet_type` field (API.md §5).
  Future<List<LedgerEntry>> getLedger({String? walletType, int limit = 50});
}

class WalletsApiImpl implements WalletsApi {
  WalletsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Wallet>> getMyWallets() async {
    final response = await _client.get('/wallets/my-wallets');
    return (response as List)
        .map((w) => Wallet.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LedgerEntry>> getLedger(
      {String? walletType, int limit = 50}) async {
    final response = await _client.get('/wallets/ledger', query: {
      'limit': limit,
      if (walletType != null) 'wallet_type': walletType,
    });
    return (response as List)
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
