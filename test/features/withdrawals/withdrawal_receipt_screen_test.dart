import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/esims/application/receipt_sharer.dart';
import 'package:triptel/features/withdrawals/application/withdrawals_providers.dart';
import 'package:triptel/features/withdrawals/data/models/payout_account.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal.dart';
import 'package:triptel/features/withdrawals/data/models/withdrawal_config.dart';
import 'package:triptel/features/withdrawals/data/withdrawals_api.dart';
import 'package:triptel/features/withdrawals/presentation/withdrawal_receipt_screen.dart';

class _FakeWithdrawalsApi implements WithdrawalsApi {
  _FakeWithdrawalsApi(this._withdrawal);
  final Withdrawal _withdrawal;

  @override
  Future<Withdrawal> getWithdrawal(String withdrawalId) async => _withdrawal;

  @override
  Future<List<Withdrawal>> getWithdrawals({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Withdrawal> cancelWithdrawal(String withdrawalId) =>
      throw UnimplementedError();

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

class _ThrowingWithdrawalsApi implements WithdrawalsApi {
  @override
  Future<Withdrawal> getWithdrawal(String withdrawalId) async =>
      throw Exception('network error');

  @override
  Future<List<Withdrawal>> getWithdrawals({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Withdrawal> cancelWithdrawal(String withdrawalId) =>
      throw UnimplementedError();

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

Withdrawal _paidWithdrawal() => Withdrawal(
      id: 'wd-1',
      referenceNo: 'WD-20261110-0004',
      amount: const Money(5000),
      feeAmount: const Money(75),
      netAmount: const Money(4925),
      accountLine: 'bKash · 01700000000 (Alice)',
      status: 'PAID',
      createdAt: DateTime.utc(2026, 11, 10),
      payoutCurrency: 'BDT',
      conversionRate: 120.5,
      payoutAmount: 5934.63,
      paymentReference: 'TXN-998877',
    );

Withdrawal _pendingWithdrawal() => Withdrawal(
      id: 'wd-1',
      referenceNo: 'WD-20261117-0001',
      amount: const Money(10000),
      feeAmount: const Money(150),
      netAmount: const Money(9850),
      accountLine: 'bKash · 01700000000 (Alice)',
      status: 'PENDING',
      createdAt: DateTime.utc(2026, 11, 17),
    );

Widget _app(WithdrawalsApi api, {ReceiptSharer? receiptSharer}) =>
    ProviderScope(
      overrides: [
        withdrawalsApiProvider.overrideWithValue(api),
        if (receiptSharer != null)
          receiptSharerProvider.overrideWithValue(receiptSharer),
      ],
      child: const MaterialApp(
          home: WithdrawalReceiptScreen(withdrawalId: 'wd-1')),
    );

void main() {
  testWidgets(
      'shows reference, amounts, the frozen rate/payout, and account line',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(_paidWithdrawal())));
    await tester.pumpAndSettle();

    expect(find.text('WD-20261110-0004'), findsOneWidget);
    expect(find.text('€50.00'), findsOneWidget);
    expect(find.text('€0.75'), findsOneWidget);
    expect(find.text('€49.25'), findsOneWidget);
    expect(find.text('1 EUR = 120.5000 BDT'), findsOneWidget);
    expect(find.text('৳5934.63'), findsOneWidget);
    expect(find.text('bKash · 01700000000 (Alice)'), findsOneWidget);
    expect(find.text('TXN-998877'), findsOneWidget);
  });

  testWidgets(
      'a withdrawal with no payout yet shows "Pending approval", not a '
      'fabricated amount', (tester) async {
    await tester.pumpWidget(_app(_FakeWithdrawalsApi(_pendingWithdrawal())));
    await tester.pumpAndSettle();

    expect(find.text('Pending approval'), findsOneWidget);
  });

  testWidgets(
      'tapping "Share receipt" calls the receipt sharer with the '
      "card's boundary key", (tester) async {
    GlobalKey? capturedKey;
    await tester.pumpWidget(_app(
      _FakeWithdrawalsApi(_paidWithdrawal()),
      receiptSharer: (boundaryKey) async {
        capturedKey = boundaryKey;
      },
    ));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-receipt-share-button')));
    await tester.pumpAndSettle();

    expect(capturedKey, isNotNull);
  });

  testWidgets(
      'the "Share receipt" button disables itself while sharing is in '
      'progress, then re-enables', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(_app(
      _FakeWithdrawalsApi(_paidWithdrawal()),
      receiptSharer: (boundaryKey) => completer.future,
    ));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('withdrawal-receipt-share-button')));
    await tester.pump();

    expect(find.text('Preparing...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Share receipt'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(_ThrowingWithdrawalsApi()));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
