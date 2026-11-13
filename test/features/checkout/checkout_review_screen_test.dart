import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/checkout/application/discounts_providers.dart';
import 'package:triptel/features/checkout/data/discounts_api.dart';
import 'package:triptel/features/checkout/data/models/discount_check_result.dart';
import 'package:triptel/features/checkout/data/models/discount_preview_result.dart';
import 'package:triptel/features/checkout/presentation/checkout_review_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FixedAuth extends AuthNotifier {
  _FixedAuth(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

const _signedInToken = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'user-1',
  username: 'alice',
  mustChangePassword: false,
);

class _FakeDiscountsApi implements DiscountsApi {
  _FakeDiscountsApi({Object? checkResult, Object? previewResult})
      : _checkResult = checkResult,
        _previewResult = previewResult;

  final Object? _checkResult; // DiscountCheckResult or an Exception.
  final Object? _previewResult; // DiscountPreviewResult or an Exception.

  @override
  Future<DiscountCheckResult> check(String code) async {
    final result = _checkResult;
    if (result is Exception) throw result;
    return result as DiscountCheckResult;
  }

  @override
  Future<DiscountPreviewResult> preview(String code, String productId) async {
    final result = _previewResult;
    if (result is Exception) throw result;
    return result as DiscountPreviewResult;
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

Widget _app({
  Object? discountResult,
  Object? previewResult,
  AuthState authState = const AuthUnauthenticated(),
}) =>
    ProviderScope(
      overrides: [
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        authNotifierProvider.overrideWith(() => _FixedAuth(authState)),
        if (discountResult != null || previewResult != null)
          discountsApiProvider.overrideWithValue(_FakeDiscountsApi(
            checkResult: discountResult,
            previewResult: previewResult,
          )),
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

  group('FR-304: authoritative re-check before charging', () {
    testWidgets(
        'no discount applied: Continue to payment skips the authoritative '
        'check entirely and shows "coming soon"', (tester) async {
      await tester.pumpWidget(_app(
          authState: const AuthAuthenticated(
        _signedInToken,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();

      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        'a guest with a discount applied skips the authoritative check '
        '(no auth, no sign-in-and-resume flow yet) and still proceeds',
        (tester) async {
      await tester.pumpWidget(_app(
        discountResult: const DiscountCheckResult(
          valid: true,
          code: 'WELCOME',
          discountType: 'PERCENT',
          value: '10',
        ),
      ));
      await tester.pumpAndSettle();
      await _openSheetAndApply(tester, 'WELCOME');

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();

      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        'signed in with a still-valid discount: the real preview call '
        'confirms it, then proceeds to "coming soon"', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        discountResult: const DiscountCheckResult(
          valid: true,
          code: 'WELCOME',
          discountType: 'PERCENT',
          value: '10',
        ),
        previewResult: const DiscountPreviewResult(
          valid: true,
          code: 'WELCOME',
          discountAmount: Money(50),
          listPrice: Money(500),
          total: Money(450),
        ),
      ));
      await tester.pumpAndSettle();
      await _openSheetAndApply(tester, 'WELCOME');

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        'signed in but the code became invalid by checkout time: shows '
        'the reason, clears the discount, and never proceeds', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        discountResult: const DiscountCheckResult(
          valid: true,
          code: 'WELCOME',
          discountType: 'PERCENT',
          value: '10',
        ),
        previewResult: const DiscountPreviewResult(
          valid: false,
          reason: 'That code has expired.',
        ),
      ));
      await tester.pumpAndSettle();
      await _openSheetAndApply(tester, 'WELCOME');
      expect(find.byKey(const ValueKey('discount-row')), findsOneWidget);

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('That code has expired.'), findsOneWidget);
      expect(find.textContaining('Payment is coming soon'), findsNothing);
      expect(find.byKey(const ValueKey('discount-row')), findsNothing);
      expect(find.text('Add a voucher code'), findsOneWidget);
    });

    testWidgets(
        'signed in, a network/404 error during the authoritative check: '
        'shows the error and never proceeds', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        discountResult: const DiscountCheckResult(
          valid: true,
          code: 'WELCOME',
          discountType: 'PERCENT',
          value: '10',
        ),
        previewResult: const ApiException(
          statusCode: 404,
          message: 'Product not found or inactive',
        ),
      ));
      await tester.pumpAndSettle();
      await _openSheetAndApply(tester, 'WELCOME');

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Product not found or inactive'), findsOneWidget);
      expect(find.textContaining('Payment is coming soon'), findsNothing);
    });
  });
}
