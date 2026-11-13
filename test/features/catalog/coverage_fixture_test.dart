import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'the real beta products fixture has the coverage_countries shape '
      'CatalogApiImpl.getCoverageCountries() expects', () {
    final raw =
        File('test/fixtures/catalog_aukus_products.json').readAsStringSync();
    final products = jsonDecode(raw) as List;

    expect(products, isNotEmpty);
    final coverage =
        (products.first as Map<String, dynamic>)['coverage_countries'];
    expect(coverage, isA<List>());
    expect((coverage as List).cast<String>(),
        ['Australia', 'United Kingdom', 'United States']);
  });
}
