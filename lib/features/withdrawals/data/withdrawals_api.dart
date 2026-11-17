import '../../../core/network/api_client.dart';
import 'models/payout_account.dart';

abstract class WithdrawalsApi {
  /// `GET /withdrawals/accounts` (auth).
  Future<List<PayoutAccount>> getAccounts();

  /// `POST /withdrawals/accounts` (auth). Max 5 accounts per user; a
  /// duplicate (same bank_name+account_number) is a 400; the first account
  /// saved always becomes the default regardless of [isDefault] (API.md
  /// §10 / backend confirmed directly).
  Future<PayoutAccount> addAccount({
    required String accountType,
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? branchName,
    String? routingNumber,
    bool isDefault = false,
  });

  /// `POST /withdrawals/accounts/{id}/default` (auth).
  Future<void> setDefaultAccount(String accountId);

  /// `DELETE /withdrawals/accounts/{id}` (auth). 400 if a pending
  /// withdrawal uses it.
  Future<void> deleteAccount(String accountId);
}

class WithdrawalsApiImpl implements WithdrawalsApi {
  WithdrawalsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<PayoutAccount>> getAccounts() async {
    final response = await _client.get('/withdrawals/accounts');
    return (response as List)
        .map((a) => PayoutAccount.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PayoutAccount> addAccount({
    required String accountType,
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? branchName,
    String? routingNumber,
    bool isDefault = false,
  }) async {
    final response = await _client.post('/withdrawals/accounts', data: {
      'account_type': accountType,
      'bank_name': bankName,
      'holder_name': holderName,
      'account_number': accountNumber,
      'branch_name': branchName,
      'routing_number': routingNumber,
      'is_default': isDefault,
    });
    return PayoutAccount.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> setDefaultAccount(String accountId) async {
    await _client.post('/withdrawals/accounts/$accountId/default');
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _client.delete('/withdrawals/accounts/$accountId');
  }
}
