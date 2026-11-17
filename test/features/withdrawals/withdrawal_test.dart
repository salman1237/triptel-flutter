import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal.dart';

void main() {
  test(
      'Withdrawal.fromJson parses the documented POST /withdrawals response '
      '(API.md section 10)', () {
    final withdrawal = Withdrawal.fromJson(const {
      'id': 'wd-1',
      'reference_no': 'WD-20261117-0001',
      'amount': '10',
      'fee_amount': '0.15',
      'net_amount': '9.85',
      'note_category': 'withdrawal',
      'note': null,
      'account': {},
      'account_line': 'bKash · 01700000000 (Alice)',
      'status': 'PENDING',
      'payout_currency': 'BDT',
      'conversion_rate': null,
      'payout_amount': null,
      'payment_reference': null,
      'has_proof': false,
      'rejection_reason': null,
      'reviewed_at': null,
      'created_at': '2026-11-17T00:00:00Z',
    });

    expect(withdrawal.referenceNo, 'WD-20261117-0001');
    expect(withdrawal.amount.eurCents, 1000);
    expect(withdrawal.feeAmount.eurCents, 15);
    expect(withdrawal.netAmount.eurCents, 985);
    expect(withdrawal.accountLine, 'bKash · 01700000000 (Alice)');
    expect(withdrawal.status, 'PENDING');
  });
}
