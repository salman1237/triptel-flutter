import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/theme/tokens.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';
import 'package:triptel/features/wallet/presentation/ledger_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi(this._entries);
  final List<LedgerEntry> _entries;
  final List<String?> walletTypeCalls = [];

  @override
  Future<List<Wallet>> getMyWallets() async => const [];

  @override
  Future<List<LedgerEntry>> getLedger(
      {String? walletType, int limit = 50}) async {
    walletTypeCalls.add(walletType);
    if (walletType == null) return _entries;
    return _entries.where((e) => e.referenceType == walletType).toList();
  }

  @override
  Future<TopupCheckout> initiateTopup(
          {required double amount, required String currency}) =>
      throw UnimplementedError();
}

LedgerEntry _entry({
  String txType = 'DEBIT',
  String referenceType = 'ORDER_PURCHASE',
  String? description = 'Purchase eSIM: Japan 1GB 7Days',
}) =>
    LedgerEntry(
      txType: txType,
      amount: const Money(500),
      balanceAfter: const Money(1000),
      referenceType: referenceType,
      description: description,
      createdAt: DateTime.utc(2026, 11, 1, 12),
    );

Widget _app(_FakeWalletsApi api) => ProviderScope(
      overrides: [
        walletsApiProvider.overrideWithValue(api),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: const MaterialApp(home: LedgerScreen()),
    );

void main() {
  testWidgets('a debit entry shows a red minus-signed amount and its label',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi([
      _entry(txType: 'DEBIT', referenceType: 'ORDER_PURCHASE'),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('eSIM purchase'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('-€5.00'));
    expect((amount.style!.color), AppColors.danger);
  });

  testWidgets('a credit entry shows a green plus-signed amount and its label',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi([
      _entry(
          txType: 'CREDIT',
          referenceType: 'REFUND',
          description: 'Refund: eSIM provisioning failed'),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('Refund'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('+€5.00'));
    expect((amount.style!.color), AppColors.success);
  });

  testWidgets('an undocumented reference_type falls back to its raw value',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi([
      _entry(referenceType: 'SOME_NEW_TYPE', description: null),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('SOME_NEW_TYPE'), findsOneWidget);
  });

  testWidgets('no transactions yet shows EmptyState, not an error',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('tapping a filter re-fetches the ledger with that wallet_type',
      (tester) async {
    final api = _FakeWalletsApi([_entry()]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(api.walletTypeCalls, [null]);

    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();

    expect(api.walletTypeCalls, [null, 'DEFAULT']);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    final container = ProviderContainer(overrides: [
      ledgerProvider.overrideWith((ref) async => throw Exception('network')),
      selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
      currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LedgerScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
