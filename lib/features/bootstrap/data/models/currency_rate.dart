/// `GET /settings/rates` entry (API.md §1): units of [currencyCode] per 1 EUR.
class CurrencyRate {
  const CurrencyRate({
    required this.currencyCode,
    required this.rateToBase,
    this.isManualOverride = false,
    this.manualRate,
  });

  final String currencyCode;
  final double rateToBase;
  final bool isManualOverride;
  final double? manualRate;

  /// The rate to actually use for conversion (manual override wins).
  double get effectiveRate =>
      isManualOverride && manualRate != null ? manualRate! : rateToBase;

  factory CurrencyRate.fromJson(Map<String, dynamic> json) => CurrencyRate(
        currencyCode: json['currency_code'] as String,
        rateToBase: double.parse(json['rate_to_base'].toString()),
        isManualOverride: json['is_manual_override'] as bool? ?? false,
        manualRate: json['manual_rate'] != null
            ? double.parse(json['manual_rate'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'currency_code': currencyCode,
        'rate_to_base': rateToBase.toString(),
        'is_manual_override': isManualOverride,
        'manual_rate': manualRate?.toString(),
      };
}
