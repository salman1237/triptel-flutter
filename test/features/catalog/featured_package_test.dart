import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/data/models/featured_package.dart';

void main() {
  test(
      'FeaturedPackage.fromJson parses the real documented GET '
      '/catalog/featured response (API.md section 3)', () {
    final package = FeaturedPackage.fromJson(const {
      'product_id': 'd291e871-d86b-47bb-b372-e8bef1eb8ed7',
      'title': 'Global139 10GB 30Days',
      'retail_price': '111.7200',
      'currency': 'USD',
      'data_amount_gb': '10.00',
      'validity_days': 30,
      'is_unlimited': false,
      'country_count': 127,
      'country_iso2': 'GL-139',
      'country_name': 'Global139',
      'country_slug': 'global139',
      'flag_url': null,
    });

    expect(package.productId, 'd291e871-d86b-47bb-b372-e8bef1eb8ed7');
    expect(package.title, 'Global139 10GB 30Days');
    expect(package.retailPrice.eurCents, 11172);
    expect(package.dataAmountGb, 10);
    expect(package.validityDays, 30);
    expect(package.isUnlimited, isFalse);
    expect(package.countryCount, 127);
    expect(package.countrySlug, 'global139');
    expect(package.flagUrl, isNull);
  });

  test(
      'country_count is null when the product has no coverage list at all '
      '(a plain VivaPe "Global" row, per API.md)', () {
    final package = FeaturedPackage.fromJson(const {
      'product_id': 'p-1',
      'title': 'Global',
      'retail_price': '9.99',
      'data_amount_gb': '1.00',
      'validity_days': 7,
      'is_unlimited': false,
      'country_count': null,
      'country_iso2': 'GL',
      'country_name': 'Global',
      'country_slug': 'global',
      'flag_url': null,
    });

    expect(package.countryCount, isNull);
  });
}
