import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_format.dart';
import 'package:triptel/core/money/money.dart';

void main() {
  group('formatMoney', () {
    test('EUR passes through at rate 1.0 with 2 decimals', () {
      final result = formatMoney(Money.parseEur('9.99'),
          currencyCode: 'EUR', rateToBase: 1.0);
      expect(result, '€9.99');
    });

    test('converts using rate_to_base (units per 1 EUR)', () {
      final result = formatMoney(Money.parseEur('1.00'),
          currencyCode: 'BDT', rateToBase: 141.656046);
      expect(result, '৳141.66');
    });

    test('JPY renders with zero decimals (API.md §0.2 zero-decimal rule)', () {
      final result = formatMoney(Money.parseEur('10.00'),
          currencyCode: 'JPY', rateToBase: 150.0);
      expect(result, '¥1500');
    });

    test('falls back to the currency code when no symbol is known', () {
      expect(currencySymbol('XYZ'), 'XYZ');
    });
  });
}
