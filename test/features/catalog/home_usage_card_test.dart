import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/presentation/home_usage_card.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

final _esim = MyEsim(
  id: 'esim-1',
  orderNo: 'ORD-TEST-1',
  productTitle: 'Japan 1GB 7Days',
  dataAmountGb: 1,
  isUnlimited: false,
  validityDays: 7,
  iccid: '',
  lpaString: '',
  qrCodeData: '',
  smdpAddress: '',
  status: 'ACTIVE',
  isMockFallback: false,
  createdAt: DateTime.utc(2026, 11, 1),
  activatedAt: DateTime.utc(2026, 11, 1),
  expiresAt: DateTime.utc(2026, 11, 20),
  isBeneficiary: false,
);

EsimStatus _status({bool isUnlimited = false}) => EsimStatus(
      esimId: 'esim-1',
      orderNo: 'ORD-TEST-1',
      product: EsimStatusProduct(
        title: 'Japan 1GB 7Days',
        validityDays: 7,
        isUnlimited: isUnlimited,
        dataAmountGb: 1,
      ),
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      matchingId: null,
      esimStatus: 'ACTIVE',
      status: const EsimStatusInfo(
        label: 'Active',
        code: 1,
        isInstalled: true,
        isActivated: true,
        deviceModel: null,
      ),
      usage: EsimUsageInfo(
        usedFormatted: '300.00 MB',
        allowanceMb: isUnlimited ? null : 1024,
        remainingMb: isUnlimited ? null : 724,
        remainingFormatted: isUnlimited ? 'Unlimited' : '724.00 MB',
        usedPct: isUnlimited ? null : 30,
        isUnlimited: isUnlimited,
      ),
      validity: EsimValidityInfo(
        days: 7,
        activatedAt: DateTime.utc(2026, 11, 1),
        expiresAt: DateTime.utc(2026, 11, 20),
        note: '',
      ),
      shareUrl: null,
      telemetry: const EsimTelemetryInfo(
          fetchedAt: null, error: null, available: true),
      history: const [],
      dailyBreakdown: const [],
    );

void main() {
  testWidgets('shows the real plan title and remaining data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeUsageCard(
          esim: _esim,
          status: _status(),
          onViewEsim: () {},
          onBuyMore: () {},
          now: DateTime.utc(2026, 11, 10),
        ),
      ),
    ));

    expect(find.text('Japan 1GB 7Days'), findsOneWidget);
    expect(find.text('724.00 MB'), findsOneWidget);
    expect(find.text('10 days left'), findsOneWidget);
  });

  testWidgets('an unlimited plan shows "Unlimited" with no ring fill',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeUsageCard(
          esim: _esim,
          status: _status(isUnlimited: true),
          onViewEsim: () {},
          onBuyMore: () {},
          now: DateTime.utc(2026, 11, 10),
        ),
      ),
    ));

    expect(find.text('Unlimited'), findsOneWidget);
  });

  testWidgets('tapping the card calls onViewEsim', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeUsageCard(
          esim: _esim,
          status: _status(),
          onViewEsim: () => tapped = true,
          onBuyMore: () {},
          now: DateTime.utc(2026, 11, 10),
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('home-usage-card')));
    expect(tapped, isTrue);
  });

  testWidgets(
      'tapping Buy more data calls onBuyMore without opening the '
      'detail screen', (tester) async {
    var viewed = false;
    var boughtMore = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeUsageCard(
          esim: _esim,
          status: _status(),
          onViewEsim: () => viewed = true,
          onBuyMore: () => boughtMore = true,
          now: DateTime.utc(2026, 11, 10),
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('home-usage-card-buy-more')));

    expect(boughtMore, isTrue);
    expect(viewed, isFalse);
  });
}
