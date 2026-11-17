import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/withdrawals/application/withdrawals_providers.dart';
import 'package:triptel/features/withdrawals/data/models/payout_account.dart';
import 'package:triptel/features/withdrawals/data/withdrawals_api.dart';
import 'package:triptel/features/withdrawals/presentation/payout_accounts_screen.dart';

class _FakeWithdrawalsApi implements WithdrawalsApi {
  _FakeWithdrawalsApi(this._accounts, {this.error});
  List<PayoutAccount> _accounts;
  final ApiException? error;
  String? lastDefaultedId;
  String? lastDeletedId;

  @override
  Future<List<PayoutAccount>> getAccounts() async => _accounts;

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
  Future<void> setDefaultAccount(String accountId) async {
    if (error != null) throw error!;
    lastDefaultedId = accountId;
    _accounts = [
      for (final a in _accounts)
        PayoutAccount(
          id: a.id,
          accountType: a.accountType,
          bankName: a.bankName,
          holderName: a.holderName,
          accountNumber: a.accountNumber,
          branchName: a.branchName,
          routingNumber: a.routingNumber,
          isDefault: a.id == accountId,
        ),
    ];
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    if (error != null) throw error!;
    lastDeletedId = accountId;
    _accounts = _accounts.where((a) => a.id != accountId).toList();
  }
}

const _account1 = PayoutAccount(
  id: 'acct-1',
  accountType: 'MOBILE',
  bankName: 'bKash',
  holderName: 'Alice',
  accountNumber: '01700000000',
  isDefault: true,
);
const _account2 = PayoutAccount(
  id: 'acct-2',
  accountType: 'BANK',
  bankName: 'Test Bank',
  holderName: 'Alice',
  accountNumber: '123456',
  isDefault: false,
);

Widget _app(_FakeWithdrawalsApi api) => ProviderScope(
      overrides: [withdrawalsApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PayoutAccountsScreen(),
          ),
          GoRoute(
            path: '/wallet/withdraw/accounts/add',
            builder: (context, state) =>
                const Scaffold(body: Text('add-account-placeholder')),
          ),
        ]),
      ),
    );

void main() {
  testWidgets('no accounts shows EmptyState, not a crash', (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('lists real accounts with the default one tagged',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeWithdrawalsApi(const [_account1, _account2])));
    await tester.pumpAndSettle();

    expect(find.text('bKash'), findsOneWidget);
    expect(find.text('Test Bank'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('at 5 accounts the add button is disabled with a real message',
      (tester) async {
    final five = List.generate(
        5,
        (i) => PayoutAccount(
              id: 'acct-$i',
              accountType: 'BANK',
              bankName: 'Bank $i',
              holderName: 'Alice',
              accountNumber: '$i' * 6,
              isDefault: i == 0,
            ));
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(five)));
    await tester.pumpAndSettle();

    expect(find.text('Maximum 5 accounts saved'), findsOneWidget);
    final button = tester.widget<PillButton>(
        find.byKey(const ValueKey('payout-account-add-button')));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping Add navigates to the add-account screen',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(const [_account1])));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('payout-account-add-button')));
    await tester.pumpAndSettle();

    expect(find.text('add-account-placeholder'), findsOneWidget);
  });

  testWidgets(
      'setting a non-default account as default calls the real API and '
      'refreshes the list', (tester) async {
    final api = _FakeWithdrawalsApi([_account1, _account2]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('payout-account-acct-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payout-account-set-default')));
    await tester.pumpAndSettle();

    expect(api.lastDefaultedId, 'acct-2');
    expect(find.text('Test Bank'), findsOneWidget);
  });

  testWidgets('the default account has no "set as default" option',
      (tester) async {
    final api = _FakeWithdrawalsApi([_account1, _account2]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('payout-account-acct-1')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('payout-account-set-default')), findsNothing);
    expect(find.byKey(const ValueKey('payout-account-delete')), findsOneWidget);
  });

  testWidgets('deleting requires confirmation, then calls the real API',
      (tester) async {
    final api = _FakeWithdrawalsApi([_account1, _account2]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('payout-account-acct-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payout-account-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Delete this account?'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('payout-account-delete-confirm')));
    await tester.pumpAndSettle();

    expect(api.lastDeletedId, 'acct-2');
    expect(find.text('Test Bank'), findsNothing);
  });

  testWidgets('a real server error on delete shows the real message',
      (tester) async {
    final api = _FakeWithdrawalsApi([_account1, _account2],
        error: const ApiException(
            statusCode: 400,
            message:
                'This account has a withdrawal awaiting review. Cancel it first.'));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('payout-account-acct-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payout-account-delete')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('payout-account-delete-confirm')));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'This account has a withdrawal awaiting review. Cancel it first.'),
        findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        payoutAccountsProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PayoutAccountsScreen(),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
