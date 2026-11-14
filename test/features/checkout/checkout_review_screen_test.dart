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
import 'package:triptel/features/checkout/application/order_poll.dart';
import 'package:triptel/features/checkout/application/order_poll_schedule.dart';
import 'package:triptel/features/checkout/application/order_status_launcher.dart';
import 'package:triptel/features/checkout/application/orders_providers.dart';
import 'package:triptel/features/checkout/application/url_launcher_provider.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/checkout/application/shurjopay_callback.dart';
import 'package:triptel/features/checkout/application/shurjopay_launcher.dart';
import 'package:triptel/features/checkout/data/models/discount_preview_result.dart';
import 'package:triptel/features/checkout/data/models/order.dart';
import 'package:triptel/features/checkout/data/models/shurjopay_checkout.dart';
import 'package:triptel/features/checkout/data/orders_api.dart';
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

class _ErroringAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      throw const ApiException(statusCode: null, message: 'Network error');
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

Order _order(String status, {EsimProfile? esimProfile}) => Order(
      id: 'order-1',
      orderNo: 'ORD-TEST-1',
      productId: 'fixed-1-7',
      totalAmount: const Money(500),
      discountAmount: const Money(0),
      status: status,
      esimProfile: esimProfile,
    );

class _FakeOrdersApi implements OrdersApi {
  _FakeOrdersApi(
      {Object? checkoutResult,
      List<String>? pollStatuses,
      Object? shurjoPayResult,
      EsimProfile? completedEsimProfile})
      : _checkoutResult = checkoutResult,
        _pollStatuses = pollStatuses ?? const ['COMPLETED'],
        _shurjoPayResult = shurjoPayResult,
        _completedEsimProfile = completedEsimProfile;

  final Object? _checkoutResult; // Order or Exception.
  final List<String> _pollStatuses;
  final Object? _shurjoPayResult; // ShurjoPayCheckout or Exception.
  final EsimProfile? _completedEsimProfile;
  var _getOrderCalls = 0;
  var initiateShurjoPayCalls = 0;

  @override
  Future<Order> checkout(
      {required String productId, String? discountCode}) async {
    final result = _checkoutResult;
    if (result is Exception) throw result;
    return result as Order? ?? _order(_pollStatuses.first);
  }

  @override
  Future<ShurjoPayCheckout> initiateShurjoPay(
      {required String productId, String? discountCode}) async {
    initiateShurjoPayCalls++;
    final result = _shurjoPayResult;
    if (result is Exception) throw result;
    return result as ShurjoPayCheckout? ??
        const ShurjoPayCheckout(
          orderId: 'order-1',
          orderNo: 'ORD-TEST-1',
          checkoutUrl: 'https://shurjopay.example/checkout',
        );
  }

  @override
  Future<Order> getOrder(String orderId) async {
    final status =
        _pollStatuses[_getOrderCalls.clamp(0, _pollStatuses.length - 1)];
    _getOrderCalls++;
    return _order(status,
        esimProfile: status == 'COMPLETED' ? _completedEsimProfile : null);
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
  List<Wallet> wallets = const [],
  Object? checkoutResult,
  List<String>? pollStatuses,
  Object? shurjoPayResult,
  ShurjoPayCallback? shurjoPayLauncherResult =
      const ShurjoPayCallback(orderId: 'order-1', failed: false),
  _FakeOrdersApi? ordersApi,
  EsimProfile? completedEsimProfile,
  EsimVerdict esimVerdict = const EsimVerdict(
    kind: EsimVerdictKind.supported,
    deviceLabel: 'Test device',
    reason: '',
  ),
}) =>
    ProviderScope(
      overrides: [
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        authNotifierProvider.overrideWith(() => _FixedAuth(authState)),
        walletsApiProvider.overrideWithValue(_FakeWalletsApi(wallets)),
        ordersApiProvider.overrideWithValue(ordersApi ??
            _FakeOrdersApi(
              checkoutResult: checkoutResult,
              pollStatuses: pollStatuses,
              shurjoPayResult: shurjoPayResult,
              completedEsimProfile: completedEsimProfile,
            )),
        shurjoPayLauncherProvider
            .overrideWithValue((context, url) async => shurjoPayLauncherResult),
        orderStatusLauncherProvider.overrideWithValue(
            (context, api, orderId) => pollOrderUntilDone(api, orderId)),
        esimVerdictProvider.overrideWith((ref) async => esimVerdict),
        urlLauncherProvider.overrideWithValue((url) async => true),
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
      'tapping "Continue to payment" (guest, no wallet) runs the real '
      'ShurjoPay checkout and shows the real order result', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to payment'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    expect(find.textContaining('eSIM is ready'), findsOneWidget);
  });

  group('FR-304: authoritative re-check before charging', () {
    testWidgets(
        'no discount applied: Continue to payment skips the authoritative '
        'check entirely and still runs the real checkout', (tester) async {
      await tester.pumpWidget(_app(
          authState: const AuthAuthenticated(
        _signedInToken,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });

    testWidgets(
        'signed in with a still-valid discount: the real preview call '
        'confirms it, then proceeds to the real checkout', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
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
        'a guest always skips straight to ShurjoPay (no wallet, no sheet) '
        'and runs the real FR-307 checkout', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.text('Choose payment method'), findsNothing);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });

    testWidgets(
        "signed in but the wallet doesn't cover the total: skips straight "
        'to ShurjoPay, no sheet, and runs the real FR-307 checkout',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.text('Choose payment method'), findsNothing);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
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

    testWidgets(
        'selecting Wallet in the sheet places a real order (FR-306) -- '
        'superseded "coming soon" placeholder, now checked in the FR-306 '
        'group below', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Payment is coming soon'), findsNothing);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });

    testWidgets(
        'a wallet-fetch error treats the guest the same as no wallet -- '
        'skips straight to ShurjoPay, never crashes', (tester) async {
      final ordersApi = _FakeOrdersApi();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
          currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
          authNotifierProvider.overrideWith(
              () => _FixedAuth(const AuthAuthenticated(_signedInToken))),
          walletsApiProvider.overrideWithValue(_ThrowingWalletsApi()),
          ordersApiProvider.overrideWithValue(ordersApi),
          shurjoPayLauncherProvider.overrideWithValue((context, url) async =>
              const ShurjoPayCallback(orderId: 'order-1', failed: false)),
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
      expect(ordersApi.initiateShurjoPayCalls, 1);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });
  });

  group('FR-306: wallet checkout + poll', () {
    testWidgets(
        'selecting Wallet places a real order and shows the completed '
        'result once polling resolves it', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        pollStatuses: const ['COMPLETED'],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
      expect(find.textContaining('eSIM is ready'), findsOneWidget);
      expect(find.textContaining('coming soon'), findsNothing);
    });

    testWidgets('a FAILED order shows the refund message, never "coming soon"',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        pollStatuses: const ['FAILED'],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('failed'), findsOneWidget);
      expect(find.textContaining('refunded'), findsOneWidget);
    });

    testWidgets(
        'still-PROCESSING after polling exhausts the schedule is reported '
        "as FR-309's still-preparing message, never as a failure "
        '(Rules.md)', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        pollStatuses: const ['PROCESSING'],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pump(const Duration(milliseconds: 300));
      // Every poll keeps returning PROCESSING, so this drains the full
      // schedule (API.md §6's real timing) before the final snack appears.
      for (final delay in orderPollSchedule()) {
        await tester.pump(delay);
      }
      await tester.pump();

      expect(
          find.text("We're still setting up your eSIM -- it will appear "
              'in My eSIMs and arrive by email.'),
          findsOneWidget);
      expect(find.textContaining('failed'), findsNothing);
    });

    testWidgets(
        'a checkout error (e.g. insufficient balance) shows the real '
        'server message, never crashes', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        checkoutResult: const ApiException(
          statusCode: 400,
          message: 'Insufficient wallet balance. Please top up.',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.text('Insufficient wallet balance. Please top up.'),
          findsOneWidget);
    });

    testWidgets(
        'selecting ShurjoPay in the sheet now runs the real FR-307 '
        'checkout instead of the old "coming soon" placeholder',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        shurjoPayLauncherResult:
            const ShurjoPayCallback(orderId: 'order-1', failed: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ShurjoPay'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('coming soon'), findsNothing);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });
  });

  group('FR-307: ShurjoPay checkout', () {
    testWidgets(
        "signed in, wallet doesn't cover the total: skips straight to "
        'ShurjoPay, opens the WebView, and polls the real order on a '
        'successful callback', (tester) async {
      final ordersApi = _FakeOrdersApi(pollStatuses: const ['COMPLETED']);
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(10), isFrozen: false),
        ],
        ordersApi: ordersApi,
        shurjoPayLauncherResult:
            const ShurjoPayCallback(orderId: 'order-1', failed: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.text('Choose payment method'), findsNothing);
      expect(ordersApi.initiateShurjoPayCalls, 1);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
      expect(find.textContaining('eSIM is ready'), findsOneWidget);
    });

    testWidgets(
        'backing out of the WebView without a terminal redirect '
        'returns to review without polling anything', (tester) async {
      final ordersApi = _FakeOrdersApi();
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(10), isFrozen: false),
        ],
        ordersApi: ordersApi,
        shurjoPayLauncherResult: null,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(ordersApi.initiateShurjoPayCalls, 1);
      expect(find.textContaining('ORD-TEST-1'), findsNothing);
      expect(
          find.byKey(const ValueKey('checkout-review-screen')), findsOneWidget);
    });

    testWidgets(
        'a callback flagged failed=true is still just a hint: the app '
        're-polls the real order and reports its actual outcome',
        (tester) async {
      final ordersApi = _FakeOrdersApi(pollStatuses: const ['COMPLETED']);
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(10), isFrozen: false),
        ],
        ordersApi: ordersApi,
        shurjoPayLauncherResult: const ShurjoPayCallback(
          orderId: 'order-1',
          failed: true,
          reason: 'user_cancelled',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
      expect(find.textContaining('eSIM is ready'), findsOneWidget);
    });

    testWidgets(
        'order-initiate failure (e.g. 502 gateway error) shows the real '
        'message, never crashes', (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(10), isFrozen: false),
        ],
        shurjoPayResult: const ApiException(
          statusCode: 502,
          message: 'Could not start ShurjoPay checkout: gateway error',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not start ShurjoPay checkout: gateway error'),
          findsOneWidget);
    });

    test(
        'isShurjoPayCallbackUrl recognizes the real triptel:// '
        'payment-callback redirect and nothing else', () {
      expect(
          isShurjoPayCallbackUrl(
              Uri.parse('triptel://payment-callback?order=abc')),
          isTrue);
      expect(isShurjoPayCallbackUrl(Uri.parse('https://triptel.co/wallet')),
          isFalse);
      expect(
          isShurjoPayCallbackUrl(Uri.parse('triptel://other-path')), isFalse);
    });

    test('parseShurjoPayCallback extracts the order id on success', () {
      final callback = parseShurjoPayCallback(
          Uri.parse('triptel://payment-callback?order=abc-123'));
      expect(callback.orderId, 'abc-123');
      expect(callback.failed, isFalse);
    });

    test('parseShurjoPayCallback extracts failure + reason', () {
      final callback = parseShurjoPayCallback(Uri.parse(
          'triptel://payment-callback?payment=failed&reason=declined'));
      expect(callback.failed, isTrue);
      expect(callback.reason, 'declined');
      expect(callback.orderId, isNull);
    });

    test(
        'ShurjoPayCheckout.fromJson accepts both checkout_url and '
        'checkoutUrl casings (API.md: "also try checkoutUrl")', () {
      final a = ShurjoPayCheckout.fromJson(const {
        'order_id': 'o1',
        'order_no': 'ORD-1',
        'checkout_url': 'https://shurjopay.example/a',
      });
      expect(a.checkoutUrl, 'https://shurjopay.example/a');

      final b = ShurjoPayCheckout.fromJson(const {
        'order_id': 'o1',
        'order_no': 'ORD-1',
        'checkoutUrl': 'https://shurjopay.example/b',
      });
      expect(b.checkoutUrl, 'https://shurjopay.example/b');
    });
  });

  group('FR-310: purchase success screen', () {
    const profile = EsimProfile(
      id: 'esim-1',
      iccid: '00000000000000000000',
      lpaString: r'LPA:1$smdp.example.invalid$ACTIVATION-CODE',
      qrCodeData: r'LPA:1$smdp.example.invalid$ACTIVATION-CODE',
      smdpAddress: 'smdp.example.invalid',
      status: 'RELEASED',
    );

    testWidgets(
        'a completed order with a real esim_profile navigates to the real '
        'purchase-success screen (QR + install), not just a snack',
        (tester) async {
      await tester.pumpWidget(_app(
        authState: const AuthAuthenticated(_signedInToken),
        wallets: const [
          Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
        ],
        pollStatuses: const ['COMPLETED'],
        completedEsimProfile: profile,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallet'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('purchase-success-screen')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('one-tap-install-button')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('go-to-my-esims-button')), findsOneWidget);
    });
  });

  group(
      'auth resolution failure never silently aborts "Continue to '
      'payment"', () {
    testWidgets(
        'a transient error resolving the signed-in session (e.g. a '
        'network hiccup refreshing GET /auth/me) is treated like a guest '
        '-- still proceeds to a real checkout attempt instead of doing '
        'nothing', (tester) async {
      final ordersApi = _FakeOrdersApi();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
          currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
          authNotifierProvider.overrideWith(_ErroringAuth.new),
          walletsApiProvider.overrideWithValue(_FakeWalletsApi(const [])),
          ordersApiProvider.overrideWithValue(ordersApi),
          shurjoPayLauncherProvider.overrideWithValue((context, url) async =>
              const ShurjoPayCallback(orderId: 'order-1', failed: false)),
        ],
        child: const MaterialApp(
          home: CheckoutReviewScreen(
            args: CheckoutReviewArgs(product: _product, countryName: 'Japan'),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Continue to payment'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(ordersApi.initiateShurjoPayCalls, 1);
      expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    });
  });
}

class _ThrowingWalletsApi implements WalletsApi {
  @override
  Future<List<Wallet>> getMyWallets() async =>
      throw const ApiException(statusCode: 500, message: 'Network error');
}
