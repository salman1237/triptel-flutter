import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/data/models/order.dart';

void main() {
  test(
      "parses a real order's shape (order_no/status/product confirmed live "
      "via GET /orders/my-esims against the beta backend; ids/iccid/lpa "
      "are synthetic placeholders -- real provisioning secrets are never "
      'committed to this public repo)', () {
    final raw = File('test/fixtures/orders_get_order.json').readAsStringSync();
    final order = Order.fromJson(jsonDecode(raw));

    expect(order.orderNo, 'ORD-20261114-4DB40D');
    expect(order.status, 'COMPLETED');
    expect(order.isCompleted, isTrue);
    expect(order.isFailed, isFalse);
    expect(order.totalAmount.eurCents, 90);
    expect(order.discountAmount.eurCents, 0);
    expect(order.esimProfile, isNotNull);
    expect(order.esimProfile!.status, 'RELEASED');
    expect(order.esimProfile!.smdpAddress, 'example.invalid');
  });

  test('esim_profile is null until provisioning completes', () {
    final order = Order.fromJson(const {
      'id': 'order-1',
      'order_no': 'ORD-TEST',
      'product_id': 'product-1',
      'total_amount': '0.9000',
      'discount_amount': '0.0000',
      'status': 'PROCESSING',
      'esim_profile': null,
    });

    expect(order.isCompleted, isFalse);
    expect(order.esimProfile, isNull);
  });
}
