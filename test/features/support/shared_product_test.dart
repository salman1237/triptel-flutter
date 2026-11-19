import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/shared_product.dart';

void main() {
  test(
      'SharedProduct.fromJson parses the documented shared_product shape '
      '(API.md section 12)', () {
    final product = SharedProduct.fromJson(const {
      'id': 'product-1',
      'title': 'Japan 3GB 15Days',
      'data_amount_gb': '3.00',
      'validity_days': 15,
      'is_unlimited': false,
      'retail_price': '18.9900',
      'currency': 'USD',
      'country_slug': 'japan',
    });

    expect(product.id, 'product-1');
    expect(product.title, 'Japan 3GB 15Days');
    expect(product.dataAmountGb, 3.0);
    expect(product.validityDays, 15);
    expect(product.isUnlimited, isFalse);
    // Every amount is EUR regardless of the API's own `currency` label
    // (CLAUDE.md hard constraint).
    expect(product.retailPrice.eurCents, 1899);
    expect(product.countrySlug, 'japan');
  });

  test('SharedProduct.fromJson defaults isUnlimited to false when absent', () {
    final product = SharedProduct.fromJson(const {
      'id': 'product-1',
      'title': 'Global Unlimited',
      'data_amount_gb': '0.00',
      'validity_days': 7,
      'retail_price': '25.0000',
      'currency': 'EUR',
      'country_slug': 'global',
    });

    expect(product.isUnlimited, isFalse);
  });
}
