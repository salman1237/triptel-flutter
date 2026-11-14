import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/orders_api.dart';
import '../presentation/order_status_screen.dart';

/// FR-308: pushes [OrderStatusScreen] and resolves once it pops with the
/// final order (or the poll's error) -- the real default. Overridable in
/// tests so they never need to pump the real step-progress screen.
typedef OrderStatusLauncher = Future<Order> Function(
    BuildContext context, OrdersApi api, String orderId);

final orderStatusLauncherProvider = Provider<OrderStatusLauncher>(
  (ref) => (context, api, orderId) {
    final completer = Completer<Order>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OrderStatusScreen(
        ordersApi: api,
        orderId: orderId,
        resultCompleter: completer,
      ),
    ));
    return completer.future;
  },
);
