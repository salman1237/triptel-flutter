import '../../../../core/money/money.dart';

/// `GET /catalog/featured` row (API.md §3, added 2026-11-18): the
/// destination-search sheet's top "Global" card. An admin-picked storefront
/// highlight (`Product.is_storefront_highlight`) -- not derived from
/// `is_featured` (a per-country recommendation, not a single global
/// selector), and not an extra field on `CountryResponse`/`ProductResponse`
/// (no automatic way to pick "the one global package" from those alone).
class FeaturedPackage {
  const FeaturedPackage({
    required this.productId,
    required this.title,
    required this.retailPrice,
    required this.dataAmountGb,
    required this.validityDays,
    required this.isUnlimited,
    required this.countryCount,
    required this.countryIso2,
    required this.countryName,
    required this.countrySlug,
    required this.flagUrl,
  });

  final String productId;
  final String title;
  final Money retailPrice;
  final double dataAmountGb;
  final int validityDays;
  final bool isUnlimited;

  /// Null when the product has no coverage list at all (true for a plain
  /// VivaPe "Global" row) -- don't show "0 countries" in that case, omit
  /// the coverage line instead.
  final int? countryCount;
  final String countryIso2;
  final String countryName;
  final String countrySlug;
  final String? flagUrl;

  factory FeaturedPackage.fromJson(Map<String, dynamic> json) =>
      FeaturedPackage(
        productId: json['product_id'] as String,
        title: json['title'] as String,
        retailPrice: Money.parseEur(json['retail_price'] as String),
        dataAmountGb: double.parse(json['data_amount_gb'] as String),
        validityDays: json['validity_days'] as int,
        isUnlimited: json['is_unlimited'] as bool? ?? false,
        countryCount: json['country_count'] as int?,
        countryIso2: json['country_iso2'] as String,
        countryName: json['country_name'] as String,
        countrySlug: json['country_slug'] as String,
        flagUrl: json['flag_url'] as String?,
      );
}
