import '../../../../core/money/money.dart';

/// A message's `shared_product` (API.md section 12, FR-C903): `null` when
/// the message isn't a product share, or when the shared product was since
/// deleted (`ON DELETE SET NULL`).
class SharedProduct {
  const SharedProduct({
    required this.id,
    required this.title,
    required this.dataAmountGb,
    required this.validityDays,
    required this.isUnlimited,
    required this.retailPrice,
    required this.countrySlug,
  });

  final String id;
  final String title;
  final double dataAmountGb;
  final int validityDays;
  final bool isUnlimited;

  /// Every stored amount is EUR regardless of the API's own `currency`
  /// label (CLAUDE.md hard constraint).
  final Money retailPrice;

  /// Same slug `GET /catalog/countries` computes (API.md section 12).
  final String countrySlug;

  factory SharedProduct.fromJson(Map<String, dynamic> json) => SharedProduct(
        id: json['id'] as String,
        title: json['title'] as String,
        dataAmountGb: double.parse(json['data_amount_gb'].toString()),
        validityDays: json['validity_days'] as int,
        isUnlimited: json['is_unlimited'] as bool? ?? false,
        retailPrice: Money.parseEur(json['retail_price'].toString()),
        countrySlug: json['country_slug'] as String,
      );
}
