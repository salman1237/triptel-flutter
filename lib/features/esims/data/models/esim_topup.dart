import '../../../../core/money/money.dart';

/// `POST /esims/{esim_id}/topup` response (API.md section 7) -- synchronous
/// wallet top-up. A supplier failure is refunded server-side and reported
/// as `status: "FAILED"` here, not an exception.
class EsimTopup {
  const EsimTopup({
    required this.id,
    required this.esimProfileId,
    required this.packageCode,
    required this.title,
    required this.dataAmountGb,
    required this.validityDays,
    required this.retailPrice,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String esimProfileId;
  final String packageCode;
  final String title;
  final double dataAmountGb;
  final int validityDays;
  final Money retailPrice;

  /// `PENDING|COMPLETED|FAILED`.
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get failed => status == 'FAILED';

  factory EsimTopup.fromJson(Map<String, dynamic> json) => EsimTopup(
        id: json['id'] as String,
        esimProfileId: json['esim_profile_id'] as String,
        packageCode: json['package_code'] as String,
        title: json['title'] as String,
        dataAmountGb: double.parse(json['data_amount_gb'] as String),
        validityDays: json['validity_days'] as int,
        retailPrice: Money.parseEur(json['retail_price'] as String),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}
