import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal_config.dart';

void main() {
  test(
      'WithdrawalConfig.fromJson parses the documented GET /withdrawals/'
      'config shape (API.md section 10)', () {
    final config = WithdrawalConfig.fromJson(const {
      'min_amount': '5',
      'max_amount': '500',
      'fee_type': 'PERCENT',
      'fee_value': '1.5',
      'payout_currency': 'BDT',
      'processing_time': '1-3 business days',
      'is_enabled': true,
      'base_currency': 'EUR',
      'note_categories': [
        'withdrawal',
        'commission',
        'refund',
        'renew',
        'business',
        'other'
      ],
      'balance': '12.00',
      'can_withdraw': false,
      'blockers': [
        'Add a bank or mobile wallet account to receive the payout.'
      ],
      'kyc_verified': false,
      'kyc_status': null,
      'account_count': 0,
    });

    expect(config.minAmount.eurCents, 500);
    expect(config.maxAmount.eurCents, 50000);
    expect(config.isPercentFee, isTrue);
    expect(config.feeValue, 1.5);
    expect(config.payoutCurrency, 'BDT');
    expect(config.balance.eurCents, 1200);
    expect(config.canWithdraw, isFalse);
    expect(config.blockers, hasLength(1));
    expect(config.kycVerified, isFalse);
    expect(config.kycStatus, isNull);
    expect(config.accountCount, 0);
    expect(config.noteCategories, hasLength(6));
  });

  test(
      'isPercentFee is false for a lowercase "flat" fee_type (the real '
      'backend source returns lowercase, confirmed by reading '
      'withdrawal_settings_svc.py directly)', () {
    final config = WithdrawalConfig.fromJson(const {
      'min_amount': '5',
      'max_amount': '500',
      'fee_type': 'flat',
      'fee_value': '2.00',
      'payout_currency': 'BDT',
      'processing_time': '1-3 business days',
      'is_enabled': true,
      'note_categories': ['withdrawal'],
      'balance': '0',
      'can_withdraw': false,
      'blockers': [],
      'kyc_verified': true,
      'account_count': 1,
    });

    expect(config.isPercentFee, isFalse);
  });
}
