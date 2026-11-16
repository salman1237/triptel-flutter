import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

void main() {
  test(
      'parses the real GET /orders/my-esims shape (order_no/status/product '
      'confirmed live against the beta backend; ids/iccid/lpa are synthetic '
      'placeholders -- real provisioning secrets are never committed to '
      'this public repo)', () {
    final json = jsonDecode(
        File('test/fixtures/orders_my_esims.json').readAsStringSync()) as List;

    final esims =
        json.map((e) => MyEsim.fromJson(e as Map<String, dynamic>)).toList();
    expect(esims, hasLength(3));

    final first = esims[0];
    expect(first.orderNo, 'ORD-20261114-6D7389');
    expect(first.productTitle, 'Japan 100MB 7Days');
    expect(first.dataAmountGb, 0.1);
    expect(first.isUnlimited, isFalse);
    expect(first.validityDays, 7);
    expect(first.status, 'RELEASED');
    expect(first.isMockFallback, isFalse);
    expect(first.activatedAt, isNull);
    expect(first.expiresAt, isNull);
    expect(first.isBeneficiary, isTrue);
    expect(first.createdAt, DateTime.parse('2026-11-14T03:46:10.490559+00:00'));

    final activated = esims[1];
    expect(activated.activatedAt, DateTime.parse('2026-11-11T06:06:43+00:00'));
    expect(activated.expiresAt, DateTime.parse('2026-12-02T06:06:43+00:00'));

    final unlimited = esims[2];
    expect(unlimited.isUnlimited, isTrue);
    expect(unlimited.isMockFallback, isTrue);
  });

  test('tolerates nulls on optional fields', () {
    final esim = MyEsim.fromJson(const {
      'id': 'esim-1',
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(esim.orderNo, '');
    expect(esim.productTitle, '');
    expect(esim.dataAmountGb, 0);
    expect(esim.isUnlimited, isFalse);
    expect(esim.validityDays, 0);
    expect(esim.activatedAt, isNull);
    expect(esim.expiresAt, isNull);
    expect(esim.isBeneficiary, isFalse);
  });
}
