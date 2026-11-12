import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';

void main() {
  group('Money.parseEur', () {
    test('parses a plain decimal API amount into EUR cents', () {
      expect(Money.parseEur('2.1000').eurCents, 210);
      expect(Money.parseEur('9.99').eurCents, 999);
      expect(Money.parseEur('0.01').eurCents, 1);
    });

    test('parses whole-number amounts', () {
      expect(Money.parseEur('24').eurCents, 2400);
      expect(Money.parseEur('24.5').eurCents, 2450);
    });

    test('parses negative amounts (refunds/debits)', () {
      expect(Money.parseEur('-5.00').eurCents, -500);
    });

    test('eurValue converts back to a double EUR amount', () {
      expect(Money.parseEur('9.99').eurValue, 9.99);
    });
  });

  group('Money arithmetic', () {
    test('adds and subtracts without touching double', () {
      final a = Money.parseEur('10.00');
      final b = Money.parseEur('2.50');
      expect((a + b).eurCents, 1250);
      expect((a - b).eurCents, 750);
    });

    test('comparison operators', () {
      final a = Money.parseEur('10.00');
      final b = Money.parseEur('2.50');
      expect(a > b, isTrue);
      expect(b < a, isTrue);
      expect(a >= a, isTrue);
      expect(a <= a, isTrue);
    });
  });
}
