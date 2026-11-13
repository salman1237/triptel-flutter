import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/data/models/discount_preview_result.dart';

void main() {
  test('parses the real beta invalid-code response', () {
    final raw =
        File('test/fixtures/discounts_preview_invalid.json').readAsStringSync();
    final result = DiscountPreviewResult.fromJson(jsonDecode(raw));

    expect(result.valid, isFalse);
    expect(result.reason, "That discount code isn't valid.");
    expect(result.discountAmount, isNull);
  });

  test("parses a valid response matching docs/API.md §4's documented shape",
      () {
    final raw =
        File('test/fixtures/discounts_preview_valid.json').readAsStringSync();
    final result = DiscountPreviewResult.fromJson(jsonDecode(raw));

    expect(result.valid, isTrue);
    expect(result.code, 'WELCOME');
    expect(result.discountAmount?.eurCents, 21);
    expect(result.listPrice?.eurCents, 210);
    expect(result.total?.eurCents, 189);
  });
}
