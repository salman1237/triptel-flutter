import '../../../../core/money/money.dart';

/// `GET /esims/{esim_id}/topup-options` row (API.md section 7). Live from
/// the supplier, never cached -- an empty list means top-up isn't available
/// for this eSIM (any non-eSIM-Access profile, or one not yet delivered)
/// and the whole section should be hidden (FR-407).
class TopupOption {
  const TopupOption({
    required this.packageCode,
    required this.title,
    required this.dataAmountGb,
    required this.validityDays,
    required this.retailPrice,
  });

  final String packageCode;
  final String title;
  final double dataAmountGb;
  final int validityDays;
  final Money retailPrice;

  factory TopupOption.fromJson(Map<String, dynamic> json) => TopupOption(
        packageCode: json['package_code'] as String,
        title: json['title'] as String,
        dataAmountGb: double.parse(json['data_amount_gb'] as String),
        validityDays: json['validity_days'] as int,
        retailPrice: Money.parseEur(json['retail_price'] as String),
      );
}
