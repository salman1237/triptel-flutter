import '../../../../core/money/money.dart';

/// `GET /catalog/destinations/{slug}` / `.../products` row (API.md §3).
class Product {
  const Product({
    required this.id,
    required this.countryId,
    required this.titleEn,
    required this.dataAmountGb,
    required this.validityDays,
    required this.retailPrice,
    required this.isUnlimited,
    required this.isActive,
    required this.isFeatured,
    this.coverageNetworks,
    this.supplierPeriodNum,
    this.coverageCountries,
  });

  final String id;
  final int countryId;
  final String titleEn;

  /// Fixed data: the plan's size. Day Pass: the TOTAL over all days (API.md
  /// §3 -- divide by [validityDays] for the per-day label). Unlimited: 0.00.
  final double dataAmountGb;
  final int validityDays;
  final Money retailPrice;
  final bool isUnlimited;
  final bool isActive;
  final bool isFeatured;
  final String? coverageNetworks;
  final int? supplierPeriodNum;
  final List<String>? coverageCountries;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        countryId: json['country_id'] as int,
        titleEn: json['title_en'] as String,
        dataAmountGb: double.parse(json['data_amount_gb'] as String),
        validityDays: json['validity_days'] as int,
        retailPrice: Money.parseEur(json['retail_price'] as String),
        isUnlimited: json['is_unlimited'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        isFeatured: json['is_featured'] as bool? ?? false,
        coverageNetworks: json['coverage_networks'] as String?,
        supplierPeriodNum: json['supplier_period_num'] as int?,
        coverageCountries:
            (json['coverage_countries'] as List?)?.cast<String>(),
      );
}
