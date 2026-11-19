import '../../../../core/money/money.dart';

/// A message's `shared_order` (API.md section 12, FR-C903): `null` when the
/// message isn't an order share, or when the shared order was since
/// deleted (`ON DELETE SET NULL` -- still a readable message, just
/// nothing left to link to).
class SharedOrder {
  const SharedOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.totalAmount,
    required this.productTitle,
    this.esimProfileId,
  });

  final String id;
  final String orderNo;
  final String status;

  /// Every stored amount is EUR regardless of the API's own `currency`
  /// label (CLAUDE.md hard constraint) -- parsed the same way as every
  /// other money field in this app.
  final Money totalAmount;
  final String productTitle;

  /// The id `GET /orders/my-esims`/`GET /esims/{id}/status` use -- null
  /// while the order hasn't provisioned an eSIM yet.
  final String? esimProfileId;

  factory SharedOrder.fromJson(Map<String, dynamic> json) => SharedOrder(
        id: json['id'] as String,
        orderNo: json['order_no'] as String,
        status: json['status'] as String,
        totalAmount: Money.parseEur(json['total_amount'].toString()),
        productTitle: json['product_title'] as String,
        esimProfileId: json['esim_profile_id'] as String?,
      );
}
