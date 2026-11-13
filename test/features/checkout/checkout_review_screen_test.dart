import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/checkout/application/discounts_providers.dart';
import 'package:triptel/features/checkout/data/discounts_api.dart';
import 'package:triptel/features/checkout/data/models/discount_check_result.dart';
import 'package:triptel/features/checkout/presentation/checkout_review_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeDiscountsApi implements DiscountsApi {
  _FakeDiscountsApi(this._result);

  final Object _result; // DiscountCheckResult or an Exception to throw.

  @override
  Future<DiscountCheckResult> check(String code) async {
    if (_result is Exception) throw _result;
    return _result as DiscountCheckResult;
  }
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

Widget _app({Object? discountResult}) => ProviderScope(
      overrides: [
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        if (discountResult != null)
          discountsApiProvider
              .overrideWithValue(_FakeDiscountsApi(discountResult)),
      ],
      child: const MaterialApp(
        home: CheckoutReviewScreen(
          args: CheckoutReviewArgs(product: _product, countryName: 'Japan'),
        ),
      ),
    );

Future<void> _openSheetAndApply(WidgetTester tester, String code) async {
  await tester.tap(find.byKey(const ValueKey('voucher-row')));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const ValueKey('voucher-code-field')), code);
  await tester.tap(find.byKey(const ValueKey('voucher-apply-button')));
  await tester.pumpAndSettle();
}

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
      'a valid PERCENT code (FR-303) applies the real estimate and updates '
      'the breakdown', (tester) async {
    await tester.pumpWidget(_app(
        discountResult: const DiscountCheckResult(
      valid: true,
      code: 'WELCOME',
      discountType: 'PERCENT',
      value: '10',
      maxDiscountAmount: Money(500),
    )));
    await tester.pumpAndSettle();

    await _openSheetAndApply(tester, 'WELCOME');

    expect(find.byKey(const ValueKey('voucher-code-field')), findsNothing);
    expect(find.text('Voucher applied'), findsOneWidget);
    expect(find.text('WELCOME'), findsOneWidget);
    // 10% of €5.00 = €0.50; total €4.50.
    expect(find.byKey(const ValueKey('discount-row')), findsOneWidget);
    expect(find.text('- €0.50'), findsOneWidget);
    expect(find.text('€4.50'), findsNWidgets(2)); // breakdown + sticky bar
  });

  testWidgets(
      'a scoped valid code shows the "confirmed after sign-in" note '
      '(FR-303)', (tester) async {
    await tester.pumpWidget(_app(
        discountResult: const DiscountCheckResult(
      valid: true,
      code: 'MEMBER10',
      discountType: 'PERCENT',
      value: '10',
      scoped: true,
    )));
    await tester.pumpAndSettle();

    await _openSheetAndApply(tester, 'MEMBER10');

    expect(find.textContaining('confirmed when you sign in'), findsOneWidget);
  });

  testWidgets(
      'an invalid code shows the reason inline and keeps the sheet open '
      '(FR-303)', (tester) async {
    await tester.pumpWidget(_app(
      discountResult: const DiscountCheckResult(
        valid: false,
        reason: "That discount code isn't valid.",
      ),
    ));
    await tester.pumpAndSettle();

    await _openSheetAndApply(tester, 'NOPE');

    expect(find.byKey(const ValueKey('voucher-code-field')), findsOneWidget);
    expect(find.text("That discount code isn't valid."), findsOneWidget);
    expect(find.byKey(const ValueKey('discount-row')), findsNothing);
  });

  testWidgets(
      'a network error while checking shows the error inline, not a crash',
      (tester) async {
    await tester.pumpWidget(_app(
      discountResult:
          const ApiException(statusCode: 500, message: 'Network error'),
    ));
    await tester.pumpAndSettle();

    await _openSheetAndApply(tester, 'WELCOME');

    expect(find.text('Network error'), findsOneWidget);
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
