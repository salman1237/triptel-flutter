import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/checkout/application/order_poll.dart';
import 'package:triptel/features/checkout/data/models/order.dart';
import 'package:triptel/features/checkout/data/models/shurjopay_checkout.dart';
import 'package:triptel/features/checkout/data/orders_api.dart';

Order _order(String status) => Order(
      id: 'order-1',
      orderNo: 'ORD-1',
      productId: 'product-1',
      totalAmount: const Money(100),
      discountAmount: const Money(0),
      status: status,
      esimProfile: null,
    );

class _ScriptedOrdersApi implements OrdersApi {
  _ScriptedOrdersApi(this._statuses);
  final List<String> _statuses;
  var _calls = 0;

  int get callCount => _calls;

  @override
  Future<Order> checkout({required String productId, String? discountCode}) =>
      throw UnimplementedError();

  @override
  Future<ShurjoPayCheckout> initiateShurjoPay(
          {required String productId, String? discountCode}) =>
      throw UnimplementedError();

  @override
  Future<Order> getOrder(String orderId) async {
    final status = _statuses[_calls.clamp(0, _statuses.length - 1)];
    _calls++;
    return _order(status);
  }
}

void main() {
  test(
      'stops as soon as the order is COMPLETED, without exhausting the '
      'schedule', () async {
    final api = _ScriptedOrdersApi(['PROCESSING', 'PROCESSING', 'COMPLETED']);
    var waits = 0;

    final result =
        await pollOrderUntilDone(api, 'order-1', wait: (d) async => waits++);

    expect(result.isCompleted, isTrue);
    expect(api.callCount, 3);
    expect(waits, 2); // waited between poll 1->2 and 2->3, not after.
  });

  test('stops as soon as the order is FAILED', () async {
    final api = _ScriptedOrdersApi(['PROCESSING', 'FAILED']);

    final result = await pollOrderUntilDone(api, 'order-1', wait: (d) async {});

    expect(result.isFailed, isTrue);
    expect(api.callCount, 2);
  });

  test(
      'never returns a "failure" for a status that is neither COMPLETED '
      'nor FAILED, even after exhausting the whole schedule (Rules.md: '
      'PROCESSING is not failure)', () async {
    final api = _ScriptedOrdersApi(['PROCESSING']);

    final result = await pollOrderUntilDone(api, 'order-1', wait: (d) async {});

    expect(result.isCompleted, isFalse);
    expect(result.isFailed, isFalse);
    expect(result.status, 'PROCESSING');
  });

  test('an immediately-COMPLETED order never waits at all', () async {
    final api = _ScriptedOrdersApi(['COMPLETED']);
    var waits = 0;

    final result =
        await pollOrderUntilDone(api, 'order-1', wait: (d) async => waits++);

    expect(result.isCompleted, isTrue);
    expect(api.callCount, 1);
    expect(waits, 0);
  });
}
