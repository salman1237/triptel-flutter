import '../../../core/network/api_client.dart';
import 'models/order.dart';

abstract class OrdersApi {
  /// FR-306: `POST /orders/checkout` (auth, password-changed) -- wallet
  /// only, 202. Never send `is_buy_for_user`/`beneficiary_*`/
  /// `auto_create_user` (merchant-only -> 403, API.md §6).
  Future<Order> checkout({required String productId, String? discountCode});

  /// `GET /orders/{id}` (auth).
  Future<Order> getOrder(String orderId);
}

class OrdersApiImpl implements OrdersApi {
  OrdersApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<Order> checkout(
      {required String productId, String? discountCode}) async {
    final response = await _client.post('/orders/checkout', data: {
      'product_id': productId,
      'payment_method': 'WALLET',
      'discount_code': discountCode,
    });
    return Order.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Order> getOrder(String orderId) async {
    final response = await _client.get('/orders/$orderId');
    return Order.fromJson(response as Map<String, dynamic>);
  }
}
