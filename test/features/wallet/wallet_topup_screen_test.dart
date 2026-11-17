import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/wallet/application/topup_callback.dart';
import 'package:triptel/features/wallet/application/topup_launcher.dart';
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';
import 'package:triptel/features/wallet/data/models/manual_deposit.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';
import 'package:triptel/features/wallet/presentation/wallet_topup_screen.dart';
import 'package:triptel/core/widgets/widgets.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi({this.checkoutResult, this.error});
  final TopupCheckout? checkoutResult;
  final ApiException? error;
  double? lastAmount;
  String? lastCurrency;

  @override
  Future<List<Wallet>> getMyWallets() async => const [];

  @override
  Future<List<LedgerEntry>> getLedger({String? walletType, int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<TopupCheckout> initiateTopup(
      {required double amount, required String currency}) async {
    lastAmount = amount;
    lastCurrency = currency;
    if (error != null) throw error!;
    return checkoutResult!;
  }

  @override
  Future<ManualDeposit> submitManualDeposit({
    required double amount,
    required String currency,
    required String bankName,
    required String transactionId,
  }) =>
      throw UnimplementedError();
}

/// WalletTopupScreen is always reached by a `context.push` from the wallet
/// overview (a sibling GoRoute), so its own `Navigator.pop()` on success
/// needs a real page underneath it, same as the production stack -- landing
/// directly on it via `initialLocation` would leave nothing to pop to.
Future<void> _pumpTopupScreen(
  WidgetTester tester,
  _FakeWalletsApi api, {
  WalletTopupResult? launcherResult =
      const WalletTopupResult(status: WalletTopupStatus.success),
}) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Text('wallet-screen-placeholder')),
    ),
    GoRoute(
      path: '/topup',
      builder: (context, state) => const WalletTopupScreen(),
    ),
    GoRoute(
      path: '/set-password',
      builder: (context, state) =>
          const Scaffold(body: Text('Set password screen')),
    ),
  ]);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      walletsApiProvider.overrideWithValue(api),
      selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
      currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      bootstrapProvider.overrideWith(
        (ref) async => const BootstrapData(
          settings: PublicSettings(
            platformName: 'Triptel',
            maintenanceMode: false,
            defaultCurrency: 'EUR',
            topupMin: Money(1),
            topupMax: Money(200000),
          ),
          rates: [],
          languages: [],
          fromCache: false,
        ),
      ),
      walletTopupLauncherProvider
          .overrideWithValue((context, checkoutUrl) async => launcherResult),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  router.push('/topup');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the EUR limits from settings', (tester) async {
    await _pumpTopupScreen(tester, _FakeWalletsApi());

    expect(find.text('Between €0.01 and €2000.00'), findsOneWidget);
  });

  testWidgets('tapping a preset fills the amount field', (tester) async {
    await _pumpTopupScreen(tester, _FakeWalletsApi());

    await tester.tap(find.byKey(const ValueKey('wallet-topup-preset-1000')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
        find.byKey(const ValueKey('wallet-topup-amount-field')));
    expect(field.controller!.text, '10.00');
  });

  testWidgets('submitting an empty amount shows a real error, not a crash',
      (tester) async {
    await _pumpTopupScreen(tester, _FakeWalletsApi());

    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
  });

  testWidgets(
      'a successful top-up sends the real amount+currency, launches '
      'ShurjoPay, and shows success', (tester) async {
    final api = _FakeWalletsApi(
        checkoutResult: const TopupCheckout(checkoutUrl: 'https://pay.test'));
    await _pumpTopupScreen(tester, api,
        launcherResult:
            const WalletTopupResult(status: WalletTopupStatus.success));

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastAmount, 25.50);
    expect(api.lastCurrency, 'EUR');
    expect(find.text('Top-up successful.'), findsOneWidget);
  });

  testWidgets('a failed gateway result shows the real failure reason',
      (tester) async {
    final api = _FakeWalletsApi(
        checkoutResult: const TopupCheckout(checkoutUrl: 'https://pay.test'));
    await _pumpTopupScreen(tester, api,
        launcherResult: const WalletTopupResult(
            status: WalletTopupStatus.failed, reason: 'not_paid'));

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text("The payment wasn't completed."), findsOneWidget);
  });

  testWidgets('a failed result with no reason shows a generic failure message',
      (tester) async {
    final api = _FakeWalletsApi(
        checkoutResult: const TopupCheckout(checkoutUrl: 'https://pay.test'));
    await _pumpTopupScreen(tester, api,
        launcherResult:
            const WalletTopupResult(status: WalletTopupStatus.failed));

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Top-up failed.'), findsOneWidget);
  });

  testWidgets(
      'a cancelled result (backed out on the gateway\'s own page) shows '
      'its own distinct message, not "failed"', (tester) async {
    final api = _FakeWalletsApi(
        checkoutResult: const TopupCheckout(checkoutUrl: 'https://pay.test'));
    await _pumpTopupScreen(tester, api,
        launcherResult:
            const WalletTopupResult(status: WalletTopupStatus.cancelled));

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Top-up cancelled.'), findsOneWidget);
    expect(find.text('Top-up failed.'), findsNothing);
  });

  testWidgets(
      'backing out of the WebView without a terminal redirect shows no '
      'message', (tester) async {
    final api = _FakeWalletsApi(
        checkoutResult: const TopupCheckout(checkoutUrl: 'https://pay.test'));
    await _pumpTopupScreen(tester, api, launcherResult: null);

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Top-up failed.'), findsNothing);
    expect(find.text('Top-up successful.'), findsNothing);
  });

  testWidgets(
      'a real password-changed 403 on initiate routes to Set Password '
      'instead of a dead-end snack', (tester) async {
    final api = _FakeWalletsApi(
        error: const ApiException(
            statusCode: 403,
            message:
                'Please set your own password before buying or moving money.'));
    await _pumpTopupScreen(tester, api);

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '25.50');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Set password screen'), findsOneWidget);
  });

  testWidgets('a different 403/400 shows the real server message',
      (tester) async {
    final api = _FakeWalletsApi(
        error: const ApiException(
            statusCode: 400,
            message: 'Amount must be between 0.01 and 2000.00 EUR'));
    await _pumpTopupScreen(tester, api);

    await tester.enterText(
        find.byKey(const ValueKey('wallet-topup-amount-field')), '99999');
    await tester.tap(find.byKey(const ValueKey('wallet-topup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Amount must be between 0.01 and 2000.00 EUR'),
        findsOneWidget);
  });

  testWidgets(
      'a failed settings/rate load shows ErrorState with a working retry, '
      'not an infinite spinner', (tester) async {
    var attempts = 0;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text('wallet-screen-placeholder')),
      ),
      GoRoute(
        path: '/topup',
        builder: (context, state) => const WalletTopupScreen(),
      ),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        walletsApiProvider.overrideWithValue(_FakeWalletsApi()),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        bootstrapProvider.overrideWith((ref) async {
          attempts++;
          throw Exception('network error');
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    router.push('/topup');
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
  });
}
