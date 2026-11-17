import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/withdrawals/data/models/payout_account.dart';

void main() {
  test(
      'PayoutAccount.fromJson parses the documented '
      'GET /withdrawals/accounts shape (API.md section 10)', () {
    final account = PayoutAccount.fromJson(const {
      'id': 'acct-1',
      'account_type': 'MOBILE',
      'bank_name': 'bKash',
      'holder_name': 'Alice',
      'account_number': '01700000000',
      'branch_name': null,
      'routing_number': null,
      'is_default': true,
    });

    expect(account.accountType, 'MOBILE');
    expect(account.bankName, 'bKash');
    expect(account.holderName, 'Alice');
    expect(account.accountNumber, '01700000000');
    expect(account.branchName, isNull);
    expect(account.isDefault, isTrue);
  });

  test('is_default defaults to false when absent', () {
    final account = PayoutAccount.fromJson(const {
      'id': 'acct-2',
      'account_type': 'BANK',
      'bank_name': 'Test Bank',
      'holder_name': 'Bob',
      'account_number': '123456',
    });
    expect(account.isDefault, isFalse);
  });
}
