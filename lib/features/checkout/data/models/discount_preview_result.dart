import '../../../../core/money/money.dart';

/// `POST /discounts/preview` response (API.md §4, auth, authoritative --
/// called right before charging, unlike FR-303's guest estimate). Unlike
/// [DiscountCheckResult], the server already computed exact EUR amounts
/// here, so [discountAmount]/[listPrice]/[total] are real [Money], not a
/// client-side estimate.
class DiscountPreviewResult {
  const DiscountPreviewResult({
    required this.valid,
    this.code,
    this.description,
    this.discountAmount,
    this.listPrice,
    this.total,
    this.reason,
  });

  final bool valid;
  final String? code;
  final String? description;
  final Money? discountAmount;
  final Money? listPrice;
  final Money? total;
  final String? reason;

  factory DiscountPreviewResult.fromJson(Map<String, dynamic> json) =>
      DiscountPreviewResult(
        valid: json['valid'] as bool? ?? false,
        code: json['code'] as String?,
        description: json['description'] as String?,
        discountAmount: json['discount_amount'] != null
            ? Money.parseEur(json['discount_amount'] as String)
            : null,
        listPrice: json['list_price'] != null
            ? Money.parseEur(json['list_price'] as String)
            : null,
        total: json['total'] != null
            ? Money.parseEur(json['total'] as String)
            : null,
        reason: json['reason'] as String?,
      );
}
