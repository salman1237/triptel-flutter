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
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';

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

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi(this._wallets);
  final List<Wallet> _wallets;

  @override
  Future<List<Wallet>> getMyWallets() async => _wallets;
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
  List<Wallet> wallets = const [],
}) =>
    ProviderScope(
      overrides: [
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        authNotifierProvider.overrideWith(() => _FixedAuth(authState)),
        walletsApiProvider.overrideWithValue(_FakeWalletsApi(wallets)),
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

  group('FR-305: payment method choice', () {
    testWidgets(
        'a guest always skips straight to ShurjoPay (no wallet, no sheet)',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(find.text('Choose payment method'), findsNothing);
      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        "signed in but the wallet doesn't cover the total: skips straight "
        'to ShurjoPay, no sheet', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(find.text('Choose payment method'), findsNothing);
      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        'signed in and the wallet (DEFAULT+REWARD) fully covers the total: '
        'shows the real payment method sheet with the real balance',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(400), isFrozen: false),
          Wallet(walletType: 'REWARD', balance: Money(200), isFrozen: false),
          Wallet(
              walletType: 'COMMISSION', balance: Money(9999), isFrozen: false),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(find.text('Choose payment method'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      // Spendable = DEFAULT(4.00) + REWARD(2.00) = 6.00; COMMISSION ignored.
      // After paying the 5.00 total: 1.00 left.
      expect(find.text('Balance €6.00 · After: €1.00'), findsOneWidget);
      expect(find.text('ShurjoPay'), findsOneWidget);
    });

    testWidgets('selecting Wallet in the sheet proceeds to "coming soon"',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });

    testWidgets(
        'a wallet-fetch error treats the guest the same as no wallet -- '
        'skips straight to ShurjoPay, never crashes', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
          currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
          authNotifierProvider.overrideWith(
              () => _FixedAuth(const AuthAuthenticated(_signedInToken))),
          walletsApiProvider.overrideWithValue(_ThrowingWalletsApi()),
        ],
        child: const MaterialApp(
          home: CheckoutReviewScreen(
            args: CheckoutReviewArgs(product: _product, countryName: 'Japan'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(find.text('Choose payment method'), findsNothing);
      expect(find.textContaining('Payment is coming soon'), findsOneWidget);
    });
  });
}

class _ThrowingWalletsApi implements WalletsApi {
  @override
  Future<List<Wallet>> getMyWallets() async =>
      throw const ApiException(statusCode: 500, message: 'Network error');
}
