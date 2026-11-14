import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/data/models/shurjopay_checkout.dart';

void main() {
  test('parses the documented order-initiate response shape', () {
    final checkout = ShurjoPayCheckout.fromJson(const {
      'order_id': 'order-1',
      'order_no': 'ORD-20261114-TEST',
      'checkout_url': 'https://shurjopay.example/pay/abc',
    });

    expect(checkout.orderId, 'order-1');
    expect(checkout.orderNo, 'ORD-20261114-TEST');
    expect(checkout.checkoutUrl, 'https://shurjopay.example/pay/abc');
  });
}
