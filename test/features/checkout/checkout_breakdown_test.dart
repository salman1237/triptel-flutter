import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/checkout/application/checkout_breakdown.dart';

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
}
