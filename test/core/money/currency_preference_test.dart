import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_preference.dart';
import 'package:triptel/features/bootstrap/data/models/currency_rate.dart';

void main() {
  group('resolveRate', () {
    test('EUR is always 1.0', () {
      expect(
          resolveRate('EUR',
              const [CurrencyRate(currencyCode: 'EUR', rateToBase: 999)]),
          1.0);
    });

    test('looks up the matching currency rate', () {
      const rates = [
        CurrencyRate(currencyCode: 'BDT', rateToBase: 141.656046),
        CurrencyRate(currencyCode: 'USD', rateToBase: 1.08),
      ];
      expect(resolveRate('BDT', rates), 141.656046);
      expect(resolveRate('USD', rates), 1.08);
    });

    test('a manual override wins over rate_to_base', () {
      const rates = [
        CurrencyRate(
            currencyCode: 'BDT',
            rateToBase: 141.65,
            isManualOverride: true,
            manualRate: 140.0),
      ];
      expect(resolveRate('BDT', rates), 140.0);
    });

    test('falls back to 1.0 for a currency the backend has no rate for', () {
      expect(resolveRate('XYZ', const []), 1.0);
    });
  });

  group('resolveInitialCurrency', () {
    test('uses the stored code when the backend still offers it', () {
      final result = resolveInitialCurrency(
        storedCode: 'BDT',
        defaultCurrency: 'EUR',
        availableCodes: ['EUR', 'BDT', 'USD'],
      );
      expect(result, 'BDT');
    });

    test('falls back to the default when nothing was stored', () {
      final result = resolveInitialCurrency(
        storedCode: null,
        defaultCurrency: 'EUR',
        availableCodes: ['EUR', 'BDT'],
      );
      expect(result, 'EUR');
    });

    test('falls back to the default when the stored code is no longer offered',
        () {
      final result = resolveInitialCurrency(
        storedCode: 'JPY',
        defaultCurrency: 'EUR',
        availableCodes: ['EUR', 'BDT'],
      );
      expect(result, 'EUR');
    });
  });
}
