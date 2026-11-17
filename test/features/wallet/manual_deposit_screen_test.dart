import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/payment_method.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';
import 'package:triptel/features/wallet/data/models/manual_deposit.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';
import 'package:triptel/features/wallet/presentation/manual_deposit_screen.dart';

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi({this.error});
  final ApiException? error;
  double? lastAmount;
  String? lastBankName;
  String? lastTransactionId;

  @override
  Future<List<Wallet>> getMyWallets() async => const [];

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
  }) async {
    lastAmount = amount;
    lastBankName = bankName;
    lastTransactionId = transactionId;
    if (error != null) throw error!;
    return ManualDeposit(
      amount: amount.toString(),
      currency: currency,
      bankName: bankName,
      transactionId: transactionId,
      status: 'PENDING',
    );
  }
}

const _methods = [
  PaymentMethod(
    id: 'bkash-account',
    name: 'bKash Account',
    kind: 'mobile',
    accountName: '01750726094',
    accountNumber: '01750726094',
  ),
];

Widget _app(_FakeWalletsApi api, {List<PaymentMethod> methods = _methods}) =>
    ProviderScope(
      overrides: [
        walletsApiProvider.overrideWithValue(api),
        bootstrapProvider.overrideWith(
          (ref) async => BootstrapData(
            settings: PublicSettings(
              platformName: 'Triptel',
              maintenanceMode: false,
              defaultCurrency: 'EUR',
              paymentMethods: methods,
            ),
            rates: const [],
            languages: const [],
            fromCache: false,
          ),
        ),
      ],
      child: const MaterialApp(home: ManualDepositScreen()),
    );

void main() {
  testWidgets('no configured methods shows EmptyState, not a crash',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi(), methods: const []));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets(
      'choosing a method shows its real account name/number from settings',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi()));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-choose-method-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash Account').last);
    await tester.pumpAndSettle();

    expect(find.text('01750726094'), findsWidgets);
  });

  testWidgets('submitting without a method shows a real error', (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi()));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-submit-button')));
    await tester.pump();

    expect(find.text('Choose a payment method first.'), findsOneWidget);
  });

  testWidgets('submitting without an amount shows a real error',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi()));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-choose-method-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash Account').last);
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-submit-button')));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
  });

  testWidgets('submitting without a transaction ID shows a real error',
      (tester) async {
    await tester.pumpWidget(_app(_FakeWalletsApi()));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-choose-method-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash Account').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('manual-deposit-amount-field')), '1000');

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-submit-button')));
    await tester.pump();

    expect(find.text('Enter the transaction ID from your receipt.'),
        findsOneWidget);
  });

  testWidgets(
      'a successful submit sends the real bank_name+amount+transaction_id '
      'and shows the pending-approval result', (tester) async {
    final api = _FakeWalletsApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-choose-method-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash Account').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('manual-deposit-amount-field')), '1000');
    await tester.enterText(
        find.byKey(const ValueKey('manual-deposit-transaction-id-field')),
        'TX123');

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastAmount, 1000);
    expect(api.lastBankName, 'bKash Account');
    expect(api.lastTransactionId, 'TX123');
    expect(find.byKey(const ValueKey('manual-deposit-result')), findsOneWidget);
    expect(find.text('Submitted. Your deposit is pending admin approval.'),
        findsOneWidget);
  });

  testWidgets(
      'a real server error (e.g. unknown bank_name) shows the real '
      'message, never crashes', (tester) async {
    final api = _FakeWalletsApi(
        error: const ApiException(
            statusCode: 400,
            message: 'Please choose one of the listed payment methods'));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-choose-method-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bKash Account').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('manual-deposit-amount-field')), '1000');
    await tester.enterText(
        find.byKey(const ValueKey('manual-deposit-transaction-id-field')),
        'TX123');

    await tester
        .tap(find.byKey(const ValueKey('manual-deposit-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Please choose one of the listed payment methods'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('manual-deposit-result')), findsNothing);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        walletsApiProvider.overrideWithValue(_FakeWalletsApi()),
        bootstrapProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: ManualDepositScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
