import '../../../../core/money/money.dart';

/// `esim_profile` on an [Order] once provisioning completes (API.md §6).
/// Only the fields this app currently needs are kept -- FR-401+ (My eSIMs)
/// will likely need the rest when built.
class EsimProfile {
  const EsimProfile({
    required this.id,
    required this.iccid,
    required this.lpaString,
    required this.qrCodeData,
    required this.smdpAddress,
    required this.status,
  });

  final String id;
  final String iccid;
  final String lpaString;
  final String qrCodeData;
  final String smdpAddress;
  final String status;

  factory EsimProfile.fromJson(Map<String, dynamic> json) => EsimProfile(
        id: json['id'] as String,
        iccid: json['iccid'] as String? ?? '',
        lpaString: json['lpa_string'] as String? ?? '',
        qrCodeData: json['qr_code_data'] as String? ?? '',
        smdpAddress: json['smdp_address'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );
}

/// `GET /orders/{id}` / `POST /orders/checkout` response (API.md §6).
/// `total_amount`/`discount_amount` are EUR regardless of the labelled
/// `currency` (API.md §0.2 -- the beta mislabels this field "USD" same as
/// `Product.currency`, so it's never read).
class Order {
  const Order({
    required this.id,
    required this.orderNo,
    required this.productId,
    required this.totalAmount,
    required this.discountAmount,
    required this.status,
    required this.esimProfile,
  });

  final String id;
  final String orderNo;
  final String productId;
  final Money totalAmount;
  final Money discountAmount;
  final String status; // PENDING|PAID|PROCESSING|COMPLETED|FAILED|CANCELLED
  final EsimProfile? esimProfile;

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNo: json['order_no'] as String? ?? '',
        productId: json['product_id'] as String? ?? '',
        totalAmount: Money.parseEur(json['total_amount'] as String? ?? '0'),
        discountAmount:
            Money.parseEur(json['discount_amount'] as String? ?? '0'),
        status: json['status'] as String? ?? 'PENDING',
        esimProfile: json['esim_profile'] != null
            ? EsimProfile.fromJson(json['esim_profile'] as Map<String, dynamic>)
            : null,
      );
}
