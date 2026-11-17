import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';

void main() {
  test('TopupCheckout.fromJson reads checkout_url', () {
    final checkout = TopupCheckout.fromJson(const {
      'checkout_url': 'https://sandbox.shurjopayment.com/pay/abc123',
    });
    expect(
        checkout.checkoutUrl, 'https://sandbox.shurjopayment.com/pay/abc123');
  });

  test(
      'TopupCheckout.fromJson accepts the alternate checkoutUrl casing '
      '(API.md: "also try checkoutUrl")', () {
    final checkout = TopupCheckout.fromJson(const {
      'checkoutUrl': 'https://sandbox.shurjopayment.com/pay/xyz789',
    });
    expect(
        checkout.checkoutUrl, 'https://sandbox.shurjopayment.com/pay/xyz789');
  });
}
