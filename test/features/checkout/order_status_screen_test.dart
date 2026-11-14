import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/checkout/data/models/order.dart';
import 'package:triptel/features/checkout/data/models/shurjopay_checkout.dart';
import 'package:triptel/features/checkout/data/orders_api.dart';
import 'package:triptel/features/checkout/presentation/order_status_screen.dart';

Order _order(String status) => Order(
      id: 'order-1',
      orderNo: 'ORD-TEST-1',
      productId: 'product-1',
      totalAmount: const Money(90),
      discountAmount: const Money(0),
      status: status,
      esimProfile: null,
    );

/// Returns [statuses] in order on successive `getOrder` calls, repeating the
/// last one once exhausted -- lets a test control exactly how many poll
/// cycles (and therefore how much elapsed time) occur before a terminal
/// status.
class _ScriptedOrdersApi implements OrdersApi {
  _ScriptedOrdersApi(this.statuses);
  final List<String> statuses;
  var _calls = 0;

  @override
  Future<Order> getOrder(String orderId) async {
    final status =
        statuses[_calls < statuses.length ? _calls : statuses.length - 1];
    _calls++;
    return _order(status);
  }

  @override
  Future<Order> checkout({required String productId, String? discountCode}) =>
      throw UnimplementedError();

  @override
  Future<ShurjoPayCheckout> initiateShurjoPay(
          {required String productId, String? discountCode}) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
      'shows "Payment confirmed" active immediately, before any poll resolves',
      (tester) async {
    // A single already-terminal status resolves with no `wait` ever
    // scheduled, so the very first frame is checked before anything settles.
    final api = _ScriptedOrdersApi(const ['COMPLETED']);
    final completer = Completer<Order>();
    await tester.pumpWidget(MaterialApp(
      home: OrderStatusScreen(
          ordersApi: api, orderId: 'order-1', resultCompleter: completer),
    ));

    expect(find.text('Setting up your eSIM'), findsOneWidget);
    expect(find.text('Payment confirmed'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'advances the step shown as elapsed poll time passes, then resolves '
      'the completer with the final order and pops', (tester) async {
    final api = _ScriptedOrdersApi(
        const ['PROCESSING', 'PROCESSING', 'PROCESSING', 'COMPLETED']);
    final completer = Completer<Order>();
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
              ordersApi: api, orderId: 'order-1', resultCompleter: completer),
        ),
      ),
    ));
    await tester.pump();

    // orderPollSchedule's first 6 delays are 2s each -- three of them
    // crosses the 3s (reservingEsim) and approaches the 10s (preparingQr)
    // thresholds.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));

    final order = await completer.future;
    expect(order.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(OrderStatusScreen), findsNothing);
  });

  testWidgets(
      'a poll error completes the completer with that error, never silently',
      (tester) async {
    final completer = Completer<Order>();
    final expectation =
        expectLater(completer.future, throwsA(isA<Exception>()));
    await tester.pumpWidget(MaterialApp(
      home: OrderStatusScreen(
        ordersApi: _ThrowingOrdersApi(),
        orderId: 'order-1',
        resultCompleter: completer,
      ),
    ));
    await tester.pump();

    await expectation;
  });
}

class _ThrowingOrdersApi implements OrdersApi {
  @override
  Future<Order> getOrder(String orderId) async =>
      throw Exception('network error');

  @override
  Future<Order> checkout({required String productId, String? discountCode}) =>
      throw UnimplementedError();

  @override
  Future<ShurjoPayCheckout> initiateShurjoPay(
          {required String productId, String? discountCode}) =>
      throw UnimplementedError();
}
