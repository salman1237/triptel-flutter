import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/data/models/discount_check_result.dart';

void main() {
  test('parses the real beta invalid-code response', () {
    final raw =
        File('test/fixtures/discounts_check_invalid.json').readAsStringSync();
    final result = DiscountCheckResult.fromJson(jsonDecode(raw));

    expect(result.valid, isFalse);
    expect(result.reason, "That discount code isn't valid.");
    expect(result.code, isNull);
  });

  test(
      'parses a PERCENT response matching docs/API.md §4\'s documented '
      'shape', () {
    final raw = File('test/fixtures/discounts_check_valid_percent.json')
        .readAsStringSync();
    final result = DiscountCheckResult.fromJson(jsonDecode(raw));

    expect(result.valid, isTrue);
    expect(result.code, 'WELCOME');
    expect(result.discountType, 'PERCENT');
    expect(result.value, '10');
    expect(result.maxDiscountAmount?.eurCents, 500);
    expect(result.scoped, isFalse);
  });
}
