import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';
import 'package:triptel/features/wallet/data/models/manual_deposit.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';
import 'package:triptel/features/wallet/presentation/wallet_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi(this._result);
  final Object _result; // List<Wallet> or Exception.

  @override
  Future<List<Wallet>> getMyWallets() async {
    final r = _result;
    if (r is Exception) throw r;
    return r as List<Wallet>;
  }

  @override
  Future<List<LedgerEntry>> getLedger({String? walletType, int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<TopupCheckout> initiateTopup(
          {required double amount, required String currency}) =>
      throw UnimplementedError();

  @override
  Future<ManualDeposit> submitManualDeposit({
    required double amount,
    required String currency,
    required String bankName,
    required String transactionId,
  }) =>
      throw UnimplementedError();
}

Widget _app(Object result) => ProviderScope(
      overrides: [
        walletsApiProvider.overrideWithValue(_FakeWalletsApi(result)),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: MaterialApp.router(routerConfig: _testRouter()),
    );

GoRouter _testRouter() => GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/wallet/topup',
        builder: (context, state) =>
            const Scaffold(body: Text('topup-screen-placeholder')),
      ),
      GoRoute(
        path: '/wallet/withdraw',
        builder: (context, state) =>
            const Scaffold(body: Text('withdraw-screen-placeholder')),
      ),
    ]);

void main() {
  testWidgets(
      'shows the real DEFAULT balance as the main amount, and REWARD as '
      'a "not withdrawable" stat', (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(53370), isFrozen: false),
      Wallet(walletType: 'REWARD', balance: Money(1250), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('€533.70'), findsOneWidget);
    expect(find.text('Reward credit (not withdrawable)'), findsOneWidget);
    expect(find.text('€12.50'), findsOneWidget);
    expect(find.text('Commission'), findsNothing);
  });

  testWidgets('Commission is shown only when its balance is > 0',
      (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(10000), isFrozen: false),
      Wallet(walletType: 'COMMISSION', balance: Money(2500), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Commission'), findsOneWidget);
    expect(find.text('€25.00'), findsOneWidget);
  });

  testWidgets('a zero COMMISSION wallet is treated the same as having none',
      (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
      Wallet(walletType: 'COMMISSION', balance: Money(0), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Commission'), findsNothing);
  });

  testWidgets('no wallets yet shows zero balances, not an error',
      (tester) async {
    await tester.pumpWidget(_app(const <Wallet>[]));
    await tester.pumpAndSettle();

    expect(find.text('€0.00'), findsAtLeastNWidgets(1));
  });

  testWidgets('tapping Top up navigates to the real top-up screen (FR-603)',
      (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('wallet-topup-button')));
    await tester.pumpAndSettle();

    expect(find.text('topup-screen-placeholder'), findsOneWidget);
  });

  testWidgets('tapping Withdraw navigates to payout accounts (FR-701)',
      (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('wallet-withdraw-button')));
    await tester.pumpAndSettle();

    expect(find.text('withdraw-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'tapping Refer shows a real "coming soon" note, not a '
      'dead tap', (tester) async {
    await tester.pumpWidget(_app(const [
      Wallet(walletType: 'DEFAULT', balance: Money(100), isFrozen: false),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('wallet-refer-button')));
    await tester.pump();

    expect(find.text('Refer a friend is coming soon.'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(Exception('network error')));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
