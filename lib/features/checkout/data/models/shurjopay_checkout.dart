/// `POST /payments/shurjopay/order-initiate` response (API.md §6). The
/// gateway payload's exact shape beyond `checkout_url` isn't documented, so
/// only the fields this app needs are parsed; `checkout_url` is tried
/// under both the documented `checkout_url` and the alternate
/// `checkoutUrl` casing API.md calls out.
class ShurjoPayCheckout {
  const ShurjoPayCheckout({
    required this.orderId,
    required this.orderNo,
    required this.checkoutUrl,
  });

  final String orderId;
  final String orderNo;
  final String checkoutUrl;

  factory ShurjoPayCheckout.fromJson(Map<String, dynamic> json) =>
      ShurjoPayCheckout(
        orderId: json['order_id'] as String,
        orderNo: json['order_no'] as String? ?? '',
        checkoutUrl: (json['checkout_url'] ?? json['checkoutUrl']) as String,
      );
}
