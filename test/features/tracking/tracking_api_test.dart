import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';

void main() {
  test(
      'EsimStatus.fromJson parses the real beta GET /esims/public/{token} '
      'shape (API.md section 7 -- "same shape" as the authenticated '
      'endpoint, share_url always null; ids/lpa/matching-id/supplier-'
      'reference are synthetic placeholders, real provisioning secrets are '
      'never committed to this public repo)', () {
    final json = jsonDecode(
            File('test/fixtures/esim_public_status.json').readAsStringSync())
        as Map<String, dynamic>;

    final status = EsimStatus.fromJson(json);

    expect(status.esimId, '0cd5db2f-c73d-459e-9008-3fd7941ab25c');
    expect(status.orderNo, 'ORD-20261116-8AAB6A');
    expect(status.product.title, 'Saudi Arabia 1GB 7Days');
    expect(status.status.label, 'IN_USE');
    expect(status.usage.remainingFormatted, '1.40 GB');
    expect(status.validity.days, 14);
    expect(status.shareUrl, isNull);
  });
}
