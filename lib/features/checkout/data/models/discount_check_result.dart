import '../../../../core/money/money.dart';

/// `POST /discounts/check` response (API.md §4, public, pre-login estimate).
/// `value` is the API's raw number: a percentage (e.g. "10" for PERCENT) or
/// an EUR amount string for any other [discountType] -- never a [Money]
/// itself, since its unit depends on [discountType].
class DiscountCheckResult {
  const DiscountCheckResult({
    required this.valid,
    this.code,
    this.description,
    this.discountType,
    this.value,
    this.maxDiscountAmount,
    this.scoped = false,
    this.reason,
  });

  final bool valid;
  final String? code;
  final String? description;
  final String? discountType;
  final String? value;
  final Money? maxDiscountAmount;
  final bool scoped;
  final String? reason;

  factory DiscountCheckResult.fromJson(Map<String, dynamic> json) =>
      DiscountCheckResult(
        valid: json['valid'] as bool? ?? false,
        code: json['code'] as String?,
        description: json['description'] as String?,
        discountType: json['discount_type'] as String?,
        value: json['value'] as String?,
        maxDiscountAmount: json['max_discount_amount'] != null
            ? Money.parseEur(json['max_discount_amount'] as String)
            : null,
        scoped: json['scoped'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}
