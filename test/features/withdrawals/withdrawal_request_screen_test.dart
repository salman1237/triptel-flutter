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
import 'package:triptel/features/withdrawals/presentation/withdrawal_request_screen.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

const _blockedConfig = WithdrawalConfig(
  minAmount: Money(500),
  maxAmount: Money(50000),
  feeType: 'percent',
  feeValue: 1.5,
  payoutCurrency: 'BDT',
  processingTime: '1-3 business days',
  isEnabled: true,
  balance: Money(0),
  canWithdraw: false,
  blockers: ['Add a bank or mobile wallet account to receive the payout.'],
  kycVerified: false,
  accountCount: 0,
  noteCategories: ['withdrawal', 'commission'],
);

const _openConfig = WithdrawalConfig(
  minAmount: Money(500),
  maxAmount: Money(50000),
  feeType: 'percent',
  feeValue: 1.5,
  payoutCurrency: 'BDT',
  processingTime: '1-3 business days',
  isEnabled: true,
  balance: Money(10000),
  canWithdraw: true,
  blockers: [],
  kycVerified: true,
  accountCount: 1,
  noteCategories: ['withdrawal', 'commission'],
);

const _account = PayoutAccount(
  id: 'acct-1',
  accountType: 'MOBILE',
  bankName: 'bKash',
  holderName: 'Alice',
  accountNumber: '01700000000',
  isDefault: true,
);

class _FakeWithdrawalsApi implements WithdrawalsApi {
  _FakeWithdrawalsApi({
    required this.config,
    this.createError,
  });
  final WithdrawalConfig config;
  final ApiException? createError;
  double? lastAmount;
  String? lastBankAccountId;
  String? lastNoteCategory;
  String? lastNote;

  @override
  Future<WithdrawalConfig> getConfig() async => config;

  @override
  Future<List<PayoutAccount>> getAccounts() async => const [_account];

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
  }) async {
    if (createError != null) throw createError!;
    lastAmount = amount;
    lastBankAccountId = bankAccountId;
    lastNoteCategory = noteCategory;
    lastNote = note;
    return Withdrawal(
      referenceNo: 'WD-20261117-0001',
      amount: Money((amount * 100).round()),
      feeAmount: const Money(0),
      netAmount: Money((amount * 100).round()),
      accountLine: 'bKash · 01700000000 (Alice)',
      status: 'PENDING',
    );
  }
}

Future<void> _pumpScreen(WidgetTester tester, _FakeWithdrawalsApi api) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Text('wallet-screen-placeholder')),
    ),
    GoRoute(
      path: '/withdraw',
      builder: (context, state) => const WithdrawalRequestScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw/accounts',
      builder: (context, state) =>
          const Scaffold(body: Text('accounts-screen-placeholder')),
    ),
    GoRoute(
      path: '/set-password',
      builder: (context, state) =>
          const Scaffold(body: Text('Set password screen')),
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
  router.push('/withdraw');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('blockers are shown verbatim', (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _blockedConfig));

    expect(
        find.text('Add a bank or mobile wallet account to receive the payout.'),
        findsOneWidget);
  });

  testWidgets('a KYC blocker shows a Verify now button', (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _blockedConfig));

    expect(find.byKey(const ValueKey('withdrawal-verify-kyc-button')),
        findsOneWidget);
  });

  testWidgets('zero accounts shows an Add a payout account button',
      (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _blockedConfig));

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-add-account-button')));
    await tester.pumpAndSettle();

    expect(find.text('accounts-screen-placeholder'), findsOneWidget);
  });

  testWidgets('no blockers shows the real request form', (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _openConfig));

    expect(
        find.byKey(const ValueKey('withdrawal-amount-field')), findsOneWidget);
    expect(find.textContaining('Available: €100.00'), findsOneWidget);
  });

  testWidgets('typing an amount shows a live PERCENT fee/net preview',
      (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _openConfig));

    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '100');
    await tester.pump();

    expect(find.text('Fee: €1.50 · You receive: €98.50'), findsOneWidget);
  });

  testWidgets('choosing an account shows its label', (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _openConfig));

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-choose-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash').last);
    await tester.pumpAndSettle();

    expect(find.text('bKash · 01700000000'), findsOneWidget);
  });

  testWidgets('submitting without an account shows a real error',
      (tester) async {
    await _pumpScreen(tester, _FakeWithdrawalsApi(config: _openConfig));

    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '100');
    await tester.tap(find.byKey(const ValueKey('withdrawal-submit-button')));
    await tester.pump();

    expect(find.text('Choose a payout account first.'), findsOneWidget);
  });

  testWidgets('an amount above the max shows a real error', (tester) async {
    final api = _FakeWithdrawalsApi(config: _openConfig);
    await _pumpScreen(tester, api);

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-choose-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '99999');
    await tester.tap(find.byKey(const ValueKey('withdrawal-submit-button')));
    await tester.pump();

    expect(
        find.text(
            'Enter an amount between the minimum and maximum withdrawal.'),
        findsOneWidget);
  });

  testWidgets(
      'a successful submit sends the real amount/account/category/note '
      'and shows the real reference number', (tester) async {
    final api = _FakeWithdrawalsApi(config: _openConfig);
    await _pumpScreen(tester, api);

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-choose-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '100');
    await tester
        .tap(find.byKey(const ValueKey('withdrawal-category-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('commission').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-note-field')), 'Please process');
    await tester.tap(find.byKey(const ValueKey('withdrawal-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastAmount, 100.0);
    expect(api.lastBankAccountId, 'acct-1');
    expect(api.lastNoteCategory, 'commission');
    expect(api.lastNote, 'Please process');
    expect(find.text('wallet-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'a real server error (e.g. insufficient balance) shows the '
      'real message, never crashes', (tester) async {
    final api = _FakeWithdrawalsApi(
      config: _openConfig,
      createError: const ApiException(
          statusCode: 400,
          message: 'Your balance is lower than the amount requested.'),
    );
    await _pumpScreen(tester, api);

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-choose-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '100');
    await tester.tap(find.byKey(const ValueKey('withdrawal-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Your balance is lower than the amount requested.'),
        findsOneWidget);
    expect(find.text('wallet-screen-placeholder'), findsNothing);
  });

  testWidgets(
      'a real password-changed 403 routes to Set Password instead of a '
      'dead-end snack', (tester) async {
    final api = _FakeWithdrawalsApi(
      config: _openConfig,
      createError: const ApiException(
          statusCode: 403,
          message:
              'Please set your own password before buying or moving money.'),
    );
    await _pumpScreen(tester, api);

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-choose-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('withdrawal-amount-field')), '100');
    await tester.tap(find.byKey(const ValueKey('withdrawal-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Set password screen'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        withdrawalConfigProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: WithdrawalRequestScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
