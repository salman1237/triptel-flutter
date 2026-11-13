import '../../../core/money/money.dart';
import '../data/models/discount_check_result.dart';

/// FR-303's guest estimate formula (API.md §4): PERCENT caps at both
/// `max_discount_amount` and the price itself; any other type caps at the
/// price. Returns zero for an invalid result.
Money estimateDiscount(DiscountCheckResult result, Money price) {
  if (!result.valid || result.value == null) return const Money(0);

  if (result.discountType == 'PERCENT') {
    final percent = double.parse(result.value!);
    var amount = Money((price.eurCents * percent / 100).round());
    final cap = result.maxDiscountAmount;
    if (cap != null && cap < amount) amount = cap;
    return amount < price ? amount : price;
  }

  final flat = Money.parseEur(result.value!);
  return flat < price ? flat : price;
}

/// FR-302's price breakdown (Architecture.md: business rules in plain
/// Dart): subtotal, discount, total. The discount comes from FR-303's guest
/// estimate ([estimateDiscount]) once a voucher is applied; FR-304's
/// authoritative `/discounts/preview` (needed before actually charging)
/// isn't wired yet.
class CheckoutBreakdown {
  const CheckoutBreakdown({
    required this.subtotal,
    this.discount = const Money(0),
  });

  final Money subtotal;
  final Money discount;

  Money get total => subtotal - discount;
  bool get hasDiscount => discount.eurCents > 0;
}
