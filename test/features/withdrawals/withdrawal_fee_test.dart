import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/withdrawals/application/withdrawal_fee.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal_config.dart';

WithdrawalConfig _config({required String feeType, required double feeValue}) =>
    WithdrawalConfig(
      minAmount: const Money(500),
      maxAmount: const Money(100000),
      feeType: feeType,
      feeValue: feeValue,
      payoutCurrency: 'BDT',
      processingTime: '1-3 business days',
      isEnabled: true,
      balance: const Money(10000),
      canWithdraw: true,
      blockers: const [],
      kycVerified: true,
      accountCount: 1,
      noteCategories: const ['withdrawal'],
    );

void main() {
  group('computeWithdrawalFee', () {
    test(
        'PERCENT: fee is amount * feeValue / 100 (mirrors the real backend '
        'compute_fee)', () {
      final config = _config(feeType: 'percent', feeValue: 1.5);
      final fee = computeWithdrawalFee(config, const Money(10000));
      expect(fee.eurCents, 150);
    });

    test('FLAT: fee is the flat feeValue regardless of amount', () {
      final config = _config(feeType: 'flat', feeValue: 2.0);
      final fee = computeWithdrawalFee(config, const Money(10000));
      expect(fee.eurCents, 200);
    });

    test(
        'is matched case-insensitively (API.md says PERCENT, backend '
        'source returns lowercase "percent")', () {
      final config = _config(feeType: 'PERCENT', feeValue: 10);
      final fee = computeWithdrawalFee(config, const Money(10000));
      expect(fee.eurCents, 1000);
    });

    test('a flat fee is capped at the amount -- net can never go negative', () {
      final config = _config(feeType: 'flat', feeValue: 50.0);
      final fee = computeWithdrawalFee(config, const Money(500));
      expect(fee.eurCents, 500);
    });
  });

  group('computeWithdrawalNet', () {
    test('net is amount minus fee', () {
      final config = _config(feeType: 'percent', feeValue: 10);
      final net = computeWithdrawalNet(config, const Money(10000));
      expect(net.eurCents, 9000);
    });

    test('a capped fee never makes net negative', () {
      final config = _config(feeType: 'flat', feeValue: 50.0);
      final net = computeWithdrawalNet(config, const Money(500));
      expect(net.eurCents, 0);
    });
  });
}
