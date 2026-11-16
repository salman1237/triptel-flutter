import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/data/models/topup_option.dart';

void main() {
  test(
      'TopupOption.fromJson parses the real beta '
      'GET /esims/{id}/topup-options fixture (FR-407)', () {
    final json = jsonDecode(
            File('test/fixtures/esim_topup_options.json').readAsStringSync())
        as List;

    final options = json
        .map((e) => TopupOption.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(options, hasLength(3));
    final first = options.first;
    expect(first.packageCode, 'TOPUP_JC063');
    expect(first.title, 'Japan 1GB 7Days');
    expect(first.dataAmountGb, 1.0);
    expect(first.validityDays, 7);
    // API.md §0.2: treat every amount as EUR regardless of the "currency"
    // label (beta labels these "USD"). retail_price "2.10" -> 210 cents.
    expect(first.retailPrice.eurCents, 210);
  });
}
