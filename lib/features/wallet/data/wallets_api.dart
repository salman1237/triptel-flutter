import '../../../core/network/api_client.dart';
import 'models/ledger_entry.dart';
import 'models/manual_deposit.dart';
import 'models/topup_checkout.dart';
import 'models/wallet.dart';

abstract class WalletsApi {
  /// `GET /wallets/my-wallets` (auth).
  Future<List<Wallet>> getMyWallets();

  /// `GET /wallets/ledger` (auth). `walletType` filters server-side; the
  /// response rows themselves carry no `wallet_type` field (API.md §5).
  Future<List<LedgerEntry>> getLedger({String? walletType, int limit = 50});

  /// `POST /payments/shurjopay/topup` (auth, password-changed). `amount` is
  /// in `currency` -- the customer's own, converted and limit-checked in EUR
  /// server-side (API.md §5).
  Future<TopupCheckout> initiateTopup(
      {required double amount, required String currency});

  /// `POST /wallets/manual-deposit` (auth). `bankName` must equal one of
  /// `/settings/public.payment_methods[].name` exactly (API.md §5).
  Future<ManualDeposit> submitManualDeposit({
    required double amount,
    required String currency,
    required String bankName,
    required String transactionId,
  });
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

  @override
  Future<TopupCheckout> initiateTopup(
      {required double amount, required String currency}) async {
    final response = await _client.post('/payments/shurjopay/topup', query: {
      'amount': amount,
      'currency': currency,
    });
    return TopupCheckout.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ManualDeposit> submitManualDeposit({
    required double amount,
    required String currency,
    required String bankName,
    required String transactionId,
  }) async {
    final response = await _client.post('/wallets/manual-deposit', data: {
      'amount': amount,
      'currency': currency,
      'bank_name': bankName,
      'transaction_id': transactionId,
    });
    return ManualDeposit.fromJson(response as Map<String, dynamic>);
  }
}
