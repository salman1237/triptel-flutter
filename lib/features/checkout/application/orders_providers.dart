import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/orders_api.dart';

final ordersApiProvider = Provider<OrdersApi>(
  (ref) => OrdersApiImpl(ref.watch(apiClientProvider)),
);
