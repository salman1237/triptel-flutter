import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/withdrawals/application/withdrawals_providers.dart';
import 'package:triptel/features/withdrawals/data/models/payout_account.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal_config.dart';
import 'package:triptel/features/withdrawals/data/withdrawals_api.dart';
import 'package:triptel/features/withdrawals/presentation/withdrawal_history_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeWithdrawalsApi implements WithdrawalsApi {
  _FakeWithdrawalsApi(this._withdrawals, {this.cancelError});
  List<Withdrawal> _withdrawals;
  final ApiException? cancelError;
  String? lastCancelledId;

  @override
  Future<List<Withdrawal>> getWithdrawals({int limit = 50}) async =>
      _withdrawals;

  @override
  Future<Withdrawal> cancelWithdrawal(String withdrawalId) async {
    if (cancelError != null) throw cancelError!;
    lastCancelledId = withdrawalId;
    _withdrawals = [
      for (final w in _withdrawals)
        if (w.id == withdrawalId)
          Withdrawal(
            id: w.id,
            referenceNo: w.referenceNo,
            amount: w.amount,
            feeAmount: w.feeAmount,
            netAmount: w.netAmount,
            accountLine: w.accountLine,
            status: 'CANCELLED',
            createdAt: w.createdAt,
          )
        else
          w,
    ];
    return _withdrawals.firstWhere((w) => w.id == withdrawalId);
  }

  @override
  Future<Withdrawal> getWithdrawal(String withdrawalId) async =>
      _withdrawals.firstWhere((w) => w.id == withdrawalId);

  @override
  Future<WithdrawalConfig> getConfig() => throw UnimplementedError();

  @override
  Future<List<PayoutAccount>> getAccounts() => throw UnimplementedError();

  @override
  Future<PayoutAccount> addAccount({
    required String accountType,
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? branchName,
    String? routingNumber,
    bool isDefault = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setDefaultAccount(String accountId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount(String accountId) => throw UnimplementedError();

  @override
  Future<Withdrawal> createWithdrawal({
    required double amount,
    required String bankAccountId,
    String? noteCategory,
    String? note,
  }) =>
      throw UnimplementedError();
}

Withdrawal _withdrawal({
  String id = 'wd-1',
  String status = 'PENDING',
  String? rejectionReason,
}) =>
    Withdrawal(
      id: id,
      referenceNo: 'WD-20261117-0001',
      amount: const Money(1000),
      feeAmount: const Money(15),
      netAmount: const Money(985),
      accountLine: 'bKash · 01700000000 (Alice)',
      status: status,
      createdAt: DateTime.utc(2026, 11, 17),
      rejectionReason: rejectionReason,
    );

Widget _app(_FakeWithdrawalsApi api) => ProviderScope(
      overrides: [
        withdrawalsApiProvider.overrideWithValue(api),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: const MaterialApp(home: WithdrawalHistoryScreen()),
    );

void main() {
  testWidgets('no withdrawals yet shows EmptyState, not a crash',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('lists a real withdrawal with its reference, amount, and chip',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi([_withdrawal()])));
    await tester.pumpAndSettle();

    expect(find.text('WD-20261117-0001'), findsOneWidget);
    expect(find.text('€10.00'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('a rejected withdrawal shows its real rejection reason',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi([
      _withdrawal(
          status: 'REJECTED',
          rejectionReason: 'Account details could not be verified.'),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Account details could not be verified.'), findsOneWidget);
  });

  testWidgets('only a PENDING withdrawal shows a Cancel button',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi([
      _withdrawal(id: 'wd-1', status: 'PENDING'),
      _withdrawal(id: 'wd-2', status: 'PAID'),
    ])));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('withdrawal-cancel-wd-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('withdrawal-cancel-wd-2')), findsNothing);
  });

  testWidgets(
      'cancelling requires confirmation, then calls the real API and '
      'refreshes', (tester) async {
    final api = _FakeWithdrawalsApi([_withdrawal()]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('withdrawal-cancel-wd-1')));
    await tester.pumpAndSettle();

    expect(find.text('Cancel this withdrawal?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('withdrawal-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(api.lastCancelledId, 'wd-1');
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byKey(const ValueKey('withdrawal-cancel-wd-1')), findsNothing);
  });

  testWidgets('a real server error on cancel shows the real message',
      (tester) async {
    final api = _FakeWithdrawalsApi(
      [_withdrawal()],
      cancelError: const ApiException(
          statusCode: 400, message: 'This request is already paid.'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('withdrawal-cancel-wd-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('withdrawal-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('This request is already paid.'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        withdrawalsProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: WithdrawalHistoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('tapping a row navigates to its FR-704 receipt', (tester) async {
    final api = _FakeWithdrawalsApi([_withdrawal()]);
    final router = GoRouter(initialLocation: '/history', routes: [
      GoRoute(
        path: '/history',
        builder: (context, state) => const WithdrawalHistoryScreen(),
      ),
      GoRoute(
        path: '/wallet/withdraw/:id/receipt',
        builder: (context, state) => Scaffold(
            body: Text('receipt-placeholder-${state.pathParameters['id']}')),
      ),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        withdrawalsApiProvider.overrideWithValue(api),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WD-20261117-0001'));
    await tester.pumpAndSettle();

    expect(find.text('receipt-placeholder-wd-1'), findsOneWidget);
  });
}
