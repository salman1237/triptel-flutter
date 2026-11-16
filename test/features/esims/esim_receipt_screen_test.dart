import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_status_providers.dart';
import 'package:triptel/features/esims/application/receipt_sharer.dart';
import 'package:triptel/features/esims/data/esim_status_api.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/esims/data/models/topup_option.dart';
import 'package:triptel/features/esims/data/models/esim_topup.dart';
import 'package:triptel/features/esims/data/models/topup_shurjopay_checkout.dart';
import 'package:triptel/features/esims/presentation/esim_receipt_screen.dart';
import 'package:triptel/core/widgets/widgets.dart';

const _lpa = r'LPA:1$smdp.example.invalid$ACTIVATION-CODE';

EsimStatus _status() => EsimStatus(
      esimId: 'esim-1',
      orderNo: 'ORD-TEST-1',
      product: const EsimStatusProduct(
        title: 'Japan 1GB 7Days',
        validityDays: 7,
        isUnlimited: false,
        dataAmountGb: 1.0,
      ),
      iccid: '8988228000000000001',
      lpaString: _lpa,
      qrCodeData: _lpa,
      smdpAddress: 'smdp.example.invalid',
      matchingId: 'ACTIVATION-CODE',
      esimStatus: 'RELEASED',
      status: const EsimStatusInfo(
        label: 'Not installed yet',
        code: 0,
        isInstalled: false,
        isActivated: false,
        deviceModel: null,
      ),
      usage: const EsimUsageInfo(
        usedFormatted: '0.00 MB',
        allowanceMb: 1024,
        remainingMb: 1024,
        remainingFormatted: '1.00 GB',
        usedPct: 0,
        isUnlimited: false,
      ),
      validity: const EsimValidityInfo(
          days: 7, activatedAt: null, expiresAt: null, note: ''),
      shareUrl: 'https://triptel.co/track/example-token',
      telemetry: const EsimTelemetryInfo(
          fetchedAt: null, error: null, available: true),
      history: const [],
      dailyBreakdown: const [],
    );

class _FakeEsimStatusApi implements EsimStatusApi {
  _FakeEsimStatusApi(this._status);
  final EsimStatus _status;

  @override
  Future<EsimStatus> getStatus(String esimId) async => _status;

  @override
  Future<EsimStatus> refresh(String esimId) async => _status;

  @override
  Future<List<TopupOption>> getTopupOptions(String esimId) async => const [];

  @override
  Future<EsimTopup> topupWithWallet(String esimId, String packageCode) =>
      throw UnimplementedError();

  @override
  Future<TopupShurjoPayCheckout> initiateTopupShurjoPay(
          String esimId, String packageCode) =>
      throw UnimplementedError();
}

Widget _app(EsimStatusApi api, {ReceiptSharer? receiptSharer}) => ProviderScope(
      overrides: [
        esimStatusApiProvider.overrideWithValue(api),
        if (receiptSharer != null)
          receiptSharerProvider.overrideWithValue(receiptSharer),
      ],
      child: const MaterialApp(home: EsimReceiptScreen(esimId: 'esim-1')),
    );

void main() {
  testWidgets('shows order no, ICCID, plan, and the QR code', (tester) async {
    await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
    await tester.pumpAndSettle();

    expect(find.text('ORD-TEST-1'), findsOneWidget);
    expect(find.text('8988228000000000001'), findsOneWidget);
    expect(find.text('Japan 1GB 7Days'), findsOneWidget);
    expect(find.text('1 GB'), findsOneWidget);
    expect(find.byType(EsimQr), findsOneWidget);
  });

  testWidgets(
      'tapping "Share receipt" calls the receipt sharer with the '
      "card's boundary key", (tester) async {
    GlobalKey? capturedKey;
    await tester.pumpWidget(_app(
      _FakeEsimStatusApi(_status()),
      receiptSharer: (boundaryKey) async {
        capturedKey = boundaryKey;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('esim-receipt-share-button')));
    await tester.pumpAndSettle();

    expect(capturedKey, isNotNull);
  });

  testWidgets(
      'the "Share receipt" button disables itself while sharing is in '
      'progress, then re-enables', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(_app(
      _FakeEsimStatusApi(_status()),
      receiptSharer: (boundaryKey) => completer.future,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('esim-receipt-share-button')));
    await tester.pump();

    expect(find.text('Preparing...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Share receipt'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        esimStatusApiProvider.overrideWithValue(_ThrowingEsimStatusApi()),
      ],
      child: const MaterialApp(home: EsimReceiptScreen(esimId: 'esim-1')),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}

class _ThrowingEsimStatusApi implements EsimStatusApi {
  @override
  Future<EsimStatus> getStatus(String esimId) async =>
      throw Exception('network error');

  @override
  Future<EsimStatus> refresh(String esimId) async =>
      throw Exception('network error');

  @override
  Future<List<TopupOption>> getTopupOptions(String esimId) async =>
      throw Exception('network error');

  @override
  Future<EsimTopup> topupWithWallet(String esimId, String packageCode) =>
      throw UnimplementedError();

  @override
  Future<TopupShurjoPayCheckout> initiateTopupShurjoPay(
          String esimId, String packageCode) =>
      throw UnimplementedError();
}
