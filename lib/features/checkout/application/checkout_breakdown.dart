import '../../../core/money/money.dart';

/// FR-302's price breakdown (Architecture.md: business rules in plain
/// Dart): subtotal, discount, total. Discount is always zero for now --
/// discount codes aren't validated anywhere yet (FR-303 guest estimate,
/// FR-304 authoritative preview are both not_started) -- but the breakdown
/// itself supports a real discount and is exercised directly by tests, same
/// disclosed-limitation pattern as FR-205's regional coverage branch.
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
