import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_usage_shape.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';

EsimUsageInfo _usage({
  bool isUnlimited = false,
  double? usedPct,
  String remainingFormatted = '1.00 GB',
}) =>
    EsimUsageInfo(
      usedFormatted: '0.00 MB',
      allowanceMb: isUnlimited ? null : 1024,
      remainingMb: isUnlimited ? null : 1024,
      remainingFormatted: remainingFormatted,
      usedPct: isUnlimited ? null : usedPct,
      isUnlimited: isUnlimited,
    );

EsimValidityInfo _validity({
  int days = 7,
  DateTime? activatedAt,
  DateTime? expiresAt,
}) =>
    EsimValidityInfo(
      days: days,
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      note: '',
    );

void main() {
  group('usageFraction', () {
    test('unlimited has no fraction (no ring fill)', () {
      expect(usageFraction(_usage(isUnlimited: true, usedPct: 50)), isNull);
    });

    test('converts the 0-100 percentage to a 0-1 fraction', () {
      expect(usageFraction(_usage(usedPct: 25)), 0.25);
      expect(usageFraction(_usage(usedPct: 0)), 0.0);
      expect(usageFraction(_usage(usedPct: 100)), 1.0);
    });

    test('clamps out-of-range percentages', () {
      expect(usageFraction(_usage(usedPct: 150)), 1.0);
      expect(usageFraction(_usage(usedPct: -10)), 0.0);
    });
  });

  group('usageCenterText', () {
    test('unlimited shows "Unlimited"', () {
      expect(usageCenterText(_usage(isUnlimited: true)), 'Unlimited');
    });

    test('otherwise shows the formatted remaining amount', () {
      expect(usageCenterText(_usage(remainingFormatted: '2.50 GB')), '2.50 GB');
    });
  });

  group('validityCountdownLabel', () {
    final now = DateTime.utc(2026, 11, 20);

    test('not yet installed', () {
      expect(validityCountdownLabel(_validity(activatedAt: null), now),
          'Validity starts on install');
    });

    test('activated with an expiry several days out', () {
      expect(
          validityCountdownLabel(
              _validity(
                activatedAt: DateTime.utc(2026, 11, 13),
                expiresAt: DateTime.utc(2026, 11, 27),
              ),
              now),
          '7 days left');
    });

    test('exactly one day left uses the singular', () {
      expect(
          validityCountdownLabel(
              _validity(
                activatedAt: DateTime.utc(2026, 11, 13),
                expiresAt: DateTime.utc(2026, 11, 21),
              ),
              now),
          '1 day left');
    });

    test('expiry is today or in the past', () {
      expect(
          validityCountdownLabel(
              _validity(
                activatedAt: DateTime.utc(2026, 11, 1),
                expiresAt: DateTime.utc(2026, 11, 20),
              ),
              now),
          'Expires today');
      expect(
          validityCountdownLabel(
              _validity(
                activatedAt: DateTime.utc(2026, 11, 1),
                expiresAt: DateTime.utc(2026, 11, 10),
              ),
              now),
          'Expires today');
    });

    test('activated with no expiry falls back to the validity-days count', () {
      expect(
          validityCountdownLabel(
              _validity(
                activatedAt: DateTime.utc(2026, 11, 13),
                expiresAt: null,
                days: 30,
              ),
              now),
          '30-day validity');
    });
  });

  group('showsTelemetryStaleBanner', () {
    test('no error -> no banner', () {
      expect(
          showsTelemetryStaleBanner(const EsimTelemetryInfo(
              fetchedAt: null, error: null, available: true)),
          isFalse);
    });

    test('an error -> shows the banner', () {
      expect(
          showsTelemetryStaleBanner(const EsimTelemetryInfo(
              fetchedAt: null, error: 'supplier unreachable', available: true)),
          isTrue);
    });
  });

  group('refreshCooldownRemaining', () {
    test('never refreshed -> no cooldown', () {
      expect(refreshCooldownRemaining(null, DateTime.utc(2026, 1, 1)),
          Duration.zero);
    });

    test('just refreshed -> close to the full cooldown', () {
      final now = DateTime.utc(2026, 1, 1, 0, 0, 10);
      final last = DateTime.utc(2026, 1, 1, 0, 0, 0);
      expect(refreshCooldownRemaining(last, now), const Duration(seconds: 20));
    });

    test('cooldown has fully elapsed -> zero, never negative', () {
      final now = DateTime.utc(2026, 1, 1, 0, 1, 0);
      final last = DateTime.utc(2026, 1, 1, 0, 0, 0);
      expect(refreshCooldownRemaining(last, now), Duration.zero);
    });
  });
}
