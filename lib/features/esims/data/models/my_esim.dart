/// `GET /orders/my-esims` response item (API.md section 7). Every profile
/// where the signed-in user is buyer **or** beneficiary; orders still
/// provisioning (no profile yet) are never in this list.
class MyEsim {
  const MyEsim({
    required this.id,
    this.orderId,
    required this.orderNo,
    required this.productTitle,
    required this.dataAmountGb,
    required this.isUnlimited,
    required this.validityDays,
    required this.iccid,
    required this.lpaString,
    required this.qrCodeData,
    required this.smdpAddress,
    required this.status,
    required this.isMockFallback,
    required this.createdAt,
    required this.activatedAt,
    required this.expiresAt,
    required this.isBeneficiary,
  });

  final String id;

  /// Added 2026-11-18 for the chat "share an order" feature (FR-C903) --
  /// the real order id `shared_order_id` expects, distinct from [id]
  /// (the eSIM profile id). `null` only for responses captured before
  /// this field existed; always present live (API.md section 7).
  final String? orderId;
  final String orderNo;
  final String productTitle;
  final double dataAmountGb;
  final bool isUnlimited;
  final int validityDays;
  final String iccid;
  final String lpaString;
  final String qrCodeData;
  final String smdpAddress;
  // ALLOCATED|RELEASED|INSTALLED|ACTIVE|EXPIRED|SUSPENDED|REVOKED|CANCELLED
  final String status;
  final bool isMockFallback;
  final DateTime createdAt;

  /// Null until the eSIM is installed (API.md: "say 'Validity starts on
  /// install'" -- never infer activation from any other field, Rules.md).
  final DateTime? activatedAt;
  final DateTime? expiresAt;

  /// True when the signed-in user is the *beneficiary* of this eSIM (it was
  /// bought for them by someone else) rather than the buyer themselves.
  final bool isBeneficiary;

  factory MyEsim.fromJson(Map<String, dynamic> json) => MyEsim(
        id: json['id'] as String,
        orderId: json['order_id'] as String?,
        orderNo: json['order_no'] as String? ?? '',
        productTitle: json['product_title'] as String? ?? '',
        dataAmountGb: (json['data_amount_gb'] as num?)?.toDouble() ?? 0,
        isUnlimited: json['is_unlimited'] as bool? ?? false,
        validityDays: json['validity_days'] as int? ?? 0,
        iccid: json['iccid'] as String? ?? '',
        lpaString: json['lpa_string'] as String? ?? '',
        qrCodeData: json['qr_code_data'] as String? ?? '',
        smdpAddress: json['smdp_address'] as String? ?? '',
        status: json['status'] as String? ?? '',
        isMockFallback: json['is_mock_fallback'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        activatedAt: json['activated_at'] != null
            ? DateTime.parse(json['activated_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        isBeneficiary: json['is_beneficiary'] as bool? ?? false,
      );
}
