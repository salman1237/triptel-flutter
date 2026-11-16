import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';

void main() {
  test(
      'parses the real GET /esims/{id}/status shape (confirmed live against '
      'the beta backend; ids/iccid/lpa/matching-id/supplier-reference are '
      'synthetic placeholders -- real provisioning secrets are never '
      'committed to this public repo)', () {
    final json =
        jsonDecode(File('test/fixtures/esim_status.json').readAsStringSync())
            as Map<String, dynamic>;

    final status = EsimStatus.fromJson(json);

    expect(status.esimId, '888dd7eb-1e83-4df4-ae4a-6a0b1ed8ff0a');
    expect(status.orderNo, 'ORD-20261114-6D7389');
    expect(status.product.title, 'Japan 100MB 7Days');
    expect(status.product.dataAmountGb, 0.10);
    expect(status.product.validityDays, 7);
    expect(status.product.isUnlimited, isFalse);
    expect(status.matchingId, 'EXAMPLEACTIVATIONCODE1');
    expect(status.esimStatus, 'RELEASED');
    expect(status.status.label, 'Not installed yet');
    expect(status.status.isInstalled, isFalse);
    expect(status.status.deviceModel, isNull);
    expect(status.usage.isUnlimited, isFalse);
    expect(status.usage.allowanceMb, 100.0);
    expect(status.usage.remainingMb, 100.0);
    expect(status.usage.remainingFormatted, '100.00 MB');
    expect(status.usage.usedPct, 0.0);
    expect(status.validity.days, 7);
    expect(status.validity.activatedAt, isNull);
    expect(status.validity.expiresAt, isNull);
    expect(status.shareUrl, 'https://beta.triptel.co/track/example-token');
    expect(status.telemetry.error, isNull);
    expect(status.telemetry.available, isTrue);
    expect(status.telemetry.fetchedAt,
        DateTime.parse('2026-11-16T17:07:25.838790+00:00'));
    expect(status.history, isEmpty);
    expect(status.dailyBreakdown, isEmpty);
  });

  test(
      'FR-406: parses non-empty history/daily_breakdown as opaque maps, '
      'ignoring non-Map entries', () {
    final status = EsimStatus.fromJson(const {
      'esim_id': 'esim-1',
      'history': [
        {'event': 'ACTIVATED', 'eid': 'device-id'},
        'not-a-map',
      ],
      'daily_breakdown': [
        {'date': '2026-11-11', 'used_mb': '120'},
      ],
    });

    expect(status.history, [
      {'event': 'ACTIVATED', 'eid': 'device-id'},
    ]);
    expect(status.dailyBreakdown, [
      {'date': '2026-11-11', 'used_mb': '120'},
    ]);
  });

  test(
      'is_unlimited:true nulls out the usage numbers (Rules.md -- no '
      'progress bar for unlimited plans)', () {
    final usage = EsimUsageInfo.fromJson(const {
      'formatted': '1.00 GB',
      'allowance_mb': '999999',
      'remaining_mb': '999999',
      'remaining_formatted': 'Unlimited',
      'used_pct': 0.0,
      'is_unlimited': true,
    });

    expect(usage.allowanceMb, isNull);
    expect(usage.remainingMb, isNull);
    expect(usage.usedPct, isNull);
    expect(usage.isUnlimited, isTrue);
  });

  test('a telemetry error is tolerated, never crashes', () {
    final telemetry = EsimTelemetryInfo.fromJson(const {
      'fetched_at': '2026-11-16T17:07:25.838790+00:00',
      'error': 'supplier unreachable',
      'available': true,
    });

    expect(telemetry.error, 'supplier unreachable');
  });

  test('tolerates a minimal/empty response without crashing', () {
    final status = EsimStatus.fromJson(const {'esim_id': 'esim-1'});

    expect(status.esimId, 'esim-1');
    expect(status.orderNo, '');
    expect(status.product.title, '');
    expect(status.matchingId, isNull);
    expect(status.shareUrl, isNull);
    expect(status.usage.isUnlimited, isFalse);
  });
}
