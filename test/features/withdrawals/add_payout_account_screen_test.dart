import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/withdrawals/application/withdrawals_providers.dart';
import 'package:triptel/features/withdrawals/data/models/payout_account.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal_config.dart';
import 'package:triptel/features/withdrawals/data/withdrawals_api.dart';
import 'package:triptel/features/withdrawals/presentation/add_payout_account_screen.dart';

class _FakeWithdrawalsApi implements WithdrawalsApi {
  _FakeWithdrawalsApi({this.error});
  final ApiException? error;
  String? lastAccountType;
  String? lastBankName;
  String? lastHolderName;
  String? lastAccountNumber;
  String? lastBranchName;
  String? lastRoutingNumber;

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
  }) async {
    if (error != null) throw error!;
    lastAccountType = accountType;
    lastBankName = bankName;
    lastHolderName = holderName;
    lastAccountNumber = accountNumber;
    lastBranchName = branchName;
    lastRoutingNumber = routingNumber;
    return PayoutAccount(
      id: 'new-acct',
      accountType: accountType,
      bankName: bankName,
      holderName: holderName,
      accountNumber: accountNumber,
      branchName: branchName,
      routingNumber: routingNumber,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> setDefaultAccount(String accountId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount(String accountId) => throw UnimplementedError();

  @override
  Future<Withdrawal> getWithdrawal(String withdrawalId) =>
      throw UnimplementedError();

  @override
  Future<WithdrawalConfig> getConfig() => throw UnimplementedError();

  @override
  Future<Withdrawal> createWithdrawal({
    required double amount,
    required String bankAccountId,
    String? noteCategory,
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Withdrawal>> getWithdrawals({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Withdrawal> cancelWithdrawal(String withdrawalId) =>
      throw UnimplementedError();
}

Future<void> _pumpAddScreen(
    WidgetTester tester, _FakeWithdrawalsApi api) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Text('accounts-list-placeholder')),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddPayoutAccountScreen(),
    ),
  ]);

  await tester.pumpWidget(ProviderScope(
    overrides: [withdrawalsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  router.push('/add');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('defaults to Bank, showing branch/routing fields',
      (tester) async {
    await _pumpAddScreen(tester, _FakeWithdrawalsApi());

    expect(find.text('Bank name'), findsOneWidget);
    expect(find.text('Branch name (optional)'), findsOneWidget);
    expect(find.text('Routing number (optional)'), findsOneWidget);
  });

  testWidgets('switching to Mobile wallet hides branch/routing fields',
      (tester) async {
    await _pumpAddScreen(tester, _FakeWithdrawalsApi());

    await tester.tap(find.text('Mobile wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile wallet provider'), findsOneWidget);
    expect(find.text('Branch name (optional)'), findsNothing);
    expect(find.text('Routing number (optional)'), findsNothing);
  });

  testWidgets('submitting a too-short bank name shows a real error',
      (tester) async {
    await _pumpAddScreen(tester, _FakeWithdrawalsApi());

    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')), 'A');
    await tester
        .tap(find.byKey(const ValueKey('payout-account-submit-button')));
    await tester.pump();

    expect(find.text('Enter the bank name.'), findsOneWidget);
  });

  testWidgets('submitting without an account number shows a real error',
      (tester) async {
    await _pumpAddScreen(tester, _FakeWithdrawalsApi());

    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')),
        'Test Bank');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-holder-name-field')),
        'Alice');
    await tester
        .tap(find.byKey(const ValueKey('payout-account-submit-button')));
    await tester.pump();

    expect(find.text('Enter a valid account number.'), findsOneWidget);
  });

  testWidgets('a successful submit sends the real fields and navigates back',
      (tester) async {
    final api = _FakeWithdrawalsApi();
    await _pumpAddScreen(tester, api);

    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')),
        'Test Bank');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-holder-name-field')),
        'Alice');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-number-field')), '123456');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-branch-name-field')),
        'Main Branch');
    await tester
        .tap(find.byKey(const ValueKey('payout-account-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastAccountType, 'BANK');
    expect(api.lastBankName, 'Test Bank');
    expect(api.lastHolderName, 'Alice');
    expect(api.lastAccountNumber, '123456');
    expect(api.lastBranchName, 'Main Branch');
    expect(find.text('accounts-list-placeholder'), findsOneWidget);
  });

  testWidgets(
      'submitting as Mobile never sends branch/routing even if '
      'previously typed', (tester) async {
    final api = _FakeWithdrawalsApi();
    await _pumpAddScreen(tester, api);

    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')),
        'Test Bank');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-branch-name-field')),
        'stale value');
    await tester.tap(find.text('Mobile wallet'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')), 'bKash');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-holder-name-field')),
        'Alice');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-number-field')),
        '01700000000');
    await tester
        .tap(find.byKey(const ValueKey('payout-account-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastAccountType, 'MOBILE');
    expect(api.lastBranchName, isNull);
    expect(api.lastRoutingNumber, isNull);
  });

  testWidgets(
      'a real server error (e.g. duplicate account) shows the '
      'real message, never crashes', (tester) async {
    final api = _FakeWithdrawalsApi(
        error: const ApiException(
            statusCode: 400, message: 'That account is already saved.'));
    await _pumpAddScreen(tester, api);

    await tester.enterText(
        find.byKey(const ValueKey('payout-account-bank-name-field')),
        'Test Bank');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-holder-name-field')),
        'Alice');
    await tester.enterText(
        find.byKey(const ValueKey('payout-account-number-field')), '123456');
    await tester
        .tap(find.byKey(const ValueKey('payout-account-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('That account is already saved.'), findsOneWidget);
    expect(find.text('accounts-list-placeholder'), findsNothing);
  });
}
