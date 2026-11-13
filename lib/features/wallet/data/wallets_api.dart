import '../../../core/network/api_client.dart';
import 'models/wallet.dart';

abstract class WalletsApi {
  /// `GET /wallets/my-wallets` (auth).
  Future<List<Wallet>> getMyWallets();
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
}
