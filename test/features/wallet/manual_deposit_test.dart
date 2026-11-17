import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/wallet/data/models/manual_deposit.dart';

void main() {
  test(
      'ManualDeposit.fromJson parses the real documented '
      'POST /wallets/manual-deposit response (API.md section 5)', () {
    final deposit = ManualDeposit.fromJson(const {
      'id': 'deposit-1',
      'amount': '1000',
      'currency': 'BDT',
      'bank_name': 'bKash Account',
      'transaction_id': 'TX123',
      'receipt_url': null,
      'status': 'PENDING',
      'created_at': '2026-11-17T00:00:00Z',
    });

    expect(deposit.amount, '1000');
    expect(deposit.currency, 'BDT');
    expect(deposit.bankName, 'bKash Account');
    expect(deposit.transactionId, 'TX123');
    expect(deposit.status, 'PENDING');
  });
}
