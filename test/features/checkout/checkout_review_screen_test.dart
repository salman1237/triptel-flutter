import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/checkout/presentation/checkout_review_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

const _product = Product(
  id: 'fixed-1-7',
  countryId: 107,
  titleEn: 'Japan 1GB 7Days (IIJ)',
  dataAmountGb: 1,
  validityDays: 7,
  retailPrice: Money(500),
  isUnlimited: false,
  isActive: true,
  isFeatured: false,
);

Widget _app() => ProviderScope(
      overrides: [
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: const MaterialApp(
        home: CheckoutReviewScreen(
          args: CheckoutReviewArgs(product: _product, countryName: 'Japan'),
        ),
      ),
    );

void main() {
  testWidgets(
      'shows the plan title, facts, and subtotal/total with no '
      'discount yet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Japan 1GB 7Days (IIJ)'), findsOneWidget);
    expect(find.textContaining('1 GB'), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);
    // Subtotal, breakdown Total, and the sticky bar's total -- all equal
    // since no discount is applied yet.
    expect(find.text('€5.00'), findsNWidgets(3));
    expect(find.byKey(const ValueKey('discount-row')), findsNothing);
  });

  testWidgets(
      'the reward credit toggle is present but disabled (display '
      'only -- backend decides)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final toggle = tester
        .widget<Switch>(find.byKey(const ValueKey('reward-credit-toggle')));
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
  });

  testWidgets('tapping the voucher row opens the code-entry sheet',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('voucher-row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('voucher-code-field')), findsOneWidget);
  });

  testWidgets(
      'typing a code and tapping Apply shows "coming soon" and closes the '
      'sheet (FR-303/304 validation does not exist yet)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('voucher-row')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('voucher-code-field')), 'WELCOME');
    await tester.tap(find.byKey(const ValueKey('voucher-apply-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('voucher-code-field')), findsNothing);
    expect(
        find.textContaining('Discount codes is coming soon'), findsOneWidget);
  });

  testWidgets(
      'tapping "Continue to payment" shows "coming soon" (FR-305+ does not '
      'exist yet)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to payment'));
    await tester.pump();

    expect(find.textContaining('Payment is coming soon'), findsOneWidget);
  });
}
