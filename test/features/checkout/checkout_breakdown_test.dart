import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/checkout/application/checkout_breakdown.dart';
import 'package:triptel/features/checkout/data/models/discount_check_result.dart';

void main() {
  test('no discount: total equals subtotal, hasDiscount is false', () {
    const breakdown = CheckoutBreakdown(subtotal: Money(500));
    expect(breakdown.total, const Money(500));
    expect(breakdown.hasDiscount, isFalse);
  });

  test('with a discount: total subtracts it, hasDiscount is true', () {
    const breakdown =
        CheckoutBreakdown(subtotal: Money(500), discount: Money(175));
    expect(breakdown.total, const Money(325));
    expect(breakdown.hasDiscount, isTrue);
  });

  group('estimateDiscount (FR-303, API.md §4\'s formula)', () {
    test('invalid result estimates zero', () {
      const result = DiscountCheckResult(valid: false, reason: 'nope');
      expect(estimateDiscount(result, const Money(500)), const Money(0));
    });

    test('PERCENT: price*value/100, capped by max_discount_amount', () {
      // price 5.00, 10% = 0.50, cap 5.00 -> uncapped 0.50 wins.
      const result = DiscountCheckResult(
        valid: true,
        discountType: 'PERCENT',
        value: '10',
        maxDiscountAmount: Money(500),
      );
      expect(estimateDiscount(result, const Money(500)), const Money(50));
    });

    test('PERCENT: the max_discount_amount cap wins when it is smaller', () {
      // price 100.00, 50% = 50.00, but capped at 5.00.
      const result = DiscountCheckResult(
        valid: true,
        discountType: 'PERCENT',
        value: '50',
        maxDiscountAmount: Money(500),
      );
      expect(estimateDiscount(result, const Money(10000)), const Money(500));
    });

    test('PERCENT: never exceeds the price itself even with no cap', () {
      const result = DiscountCheckResult(
        valid: true,
        discountType: 'PERCENT',
        value: '200',
      );
      expect(estimateDiscount(result, const Money(500)), const Money(500));
    });

    test('non-PERCENT (flat): min(value, price)', () {
      const result = DiscountCheckResult(
        valid: true,
        discountType: 'FLAT',
        value: '2.00',
      );
      expect(estimateDiscount(result, const Money(500)), const Money(200));
    });

    test('non-PERCENT (flat): capped at the price when value exceeds it', () {
      const result = DiscountCheckResult(
        valid: true,
        discountType: 'FLAT',
        value: '20.00',
      );
      expect(estimateDiscount(result, const Money(500)), const Money(500));
    });
  });
}
