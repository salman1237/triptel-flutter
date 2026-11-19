import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/shared_order.dart';

void main() {
  test(
      'SharedOrder.fromJson parses the documented shared_order shape '
      '(API.md section 12)', () {
    final order = SharedOrder.fromJson(const {
      'id': 'order-1',
      'order_no': 'ORD-261119-0001',
      'status': 'COMPLETED',
      'total_amount': '12.5000',
      'currency': 'USD',
      'product_title': 'Bangladesh 1GB 7Days',
      'esim_profile_id': 'esim-1',
    });

    expect(order.id, 'order-1');
    expect(order.orderNo, 'ORD-261119-0001');
    expect(order.status, 'COMPLETED');
    // Every amount is EUR regardless of the API's own `currency` label
    // (CLAUDE.md hard constraint) -- parsed the same as every other
    // money field in this app, never converted from the labelled currency.
    expect(order.totalAmount.eurCents, 1250);
    expect(order.productTitle, 'Bangladesh 1GB 7Days');
    expect(order.esimProfileId, 'esim-1');
  });

  test(
      'SharedOrder.fromJson leaves esimProfileId null when not yet provisioned',
      () {
    final order = SharedOrder.fromJson(const {
      'id': 'order-1',
      'order_no': 'ORD-261119-0001',
      'status': 'PENDING',
      'total_amount': '5.0000',
      'currency': 'EUR',
      'product_title': 'Japan 3GB 15Days',
      'esim_profile_id': null,
    });

    expect(order.esimProfileId, isNull);
  });
}
