import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/data/models/product.dart';

void main() {
  test('Destination.fromJson parses the real beta Japan fixture', () {
    final raw =
        File('test/fixtures/catalog_japan_destination.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final destination = Destination.fromJson(json);

    expect(destination.country.nameEn, 'Japan');
    expect(destination.products, hasLength(75));

    final fixed =
        destination.products.firstWhere((p) => p.titleEn == 'Japan 1GB 7Days');
    expect(fixed.dataAmountGb, 1.0);
    expect(fixed.validityDays, 7);
    expect(fixed.isUnlimited, false);
    expect(fixed.supplierPeriodNum, isNull);
    // API.md says: treat every amount as EUR regardless of the "currency"
    // label (beta labels these "USD"). retail_price "2.1000" -> 210 cents.
    expect(fixed.retailPrice.eurCents, 210);
  });

  test('missing optional fields fall back safely', () {
    final product = Product.fromJson(const {
      'id': 'abc',
      'country_id': 1,
      'title_en': 'Test plan',
      'data_amount_gb': '1.00',
      'validity_days': 7,
      'retail_price': '1.0000',
    });

    expect(product.isUnlimited, false);
    expect(product.isActive, true);
    expect(product.isFeatured, false);
    expect(product.coverageNetworks, isNull);
    expect(product.supplierPeriodNum, isNull);
    expect(product.coverageCountries, isNull);
  });
}
