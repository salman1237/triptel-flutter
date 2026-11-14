import 'dart:async';

import '../data/models/order.dart';
import '../data/orders_api.dart';
import 'order_poll_schedule.dart';

/// FR-306: polls `GET /orders/{id}` on [orderPollSchedule]'s delays, stopping
/// early on `COMPLETED` or `FAILED`. Anything else -- including exhausting
/// the whole schedule -- is "still processing", never a failure (Rules.md,
/// API.md §6: the backend auto-refunds real failures and emails the eSIM
/// when ready). [wait] is injectable so tests can skip real delays.
Future<Order> pollOrderUntilDone(
  OrdersApi api,
  String orderId, {
  Future<void> Function(Duration) wait = Future.delayed,
}) async {
  var order = await api.getOrder(orderId);
  for (final delay in orderPollSchedule()) {
    if (order.isCompleted || order.isFailed) return order;
    await wait(delay);
    order = await api.getOrder(orderId);
  }
  return order;
}
