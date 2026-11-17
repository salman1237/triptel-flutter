import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/tracking/application/tracking_providers.dart';
import 'package:triptel/features/tracking/data/tracking_api.dart';
import 'package:triptel/features/tracking/presentation/tracking_screen.dart';

const _lpa = r'LPA:1$smdp.example.invalid$EXAMPLE-ACTIVATION';

EsimStatus _status() => EsimStatus(
      esimId: 'esim-1',
      orderNo: 'ORD-TEST-1',
      product: const EsimStatusProduct(
        title: 'Saudi Arabia 1GB 7Days',
        validityDays: 7,
        isUnlimited: false,
        dataAmountGb: 1.0,
      ),
      iccid: '',
      lpaString: _lpa,
      qrCodeData: _lpa,
      smdpAddress: 'smdp.example.invalid',
      matchingId: 'EXAMPLE-ACTIVATION',
      esimStatus: 'RELEASED',
      status: const EsimStatusInfo(
        label: 'IN_USE',
        code: 1,
        isInstalled: true,
        isActivated: true,
        deviceModel: null,
      ),
      usage: const EsimUsageInfo(
        usedFormatted: '617.10 MB',
        allowanceMb: 2048,
        remainingMb: 1430.9,
        remainingFormatted: '1.40 GB',
        usedPct: 30.1,
        isUnlimited: false,
      ),
      validity: EsimValidityInfo(
        days: 14,
        activatedAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 14, hours: 1)),
        note: '',
      ),
      shareUrl: null,
      telemetry: const EsimTelemetryInfo(
          fetchedAt: null, error: null, available: true),
      history: const [],
      dailyBreakdown: const [],
    );

class _FakeTrackingApi implements TrackingApi {
  _FakeTrackingApi({this.result});
  final Object? result; // EsimStatus or Exception.
  String? lastToken;

  @override
  Future<EsimStatus> getPublicStatus(String token) async {
    lastToken = token;
    final r = result;
    if (r is Exception) throw r;
    return r as EsimStatus? ?? _status();
  }
}

final _bootstrapWithSupport = BootstrapData(
  settings: const PublicSettings(
    platformName: 'Triptel',
    maintenanceMode: false,
    defaultCurrency: 'EUR',
    supportEmail: 'support@triptel.co',
    supportPhone: '+8801979891996',
  ),
  rates: const [],
  languages: const [],
  fromCache: false,
);

Widget _app(TrackingApi api, {bool withSupportSettings = true}) =>
    ProviderScope(
      overrides: [
        trackingApiProvider.overrideWithValue(api),
        if (withSupportSettings)
          bootstrapProvider.overrideWith((ref) async => _bootstrapWithSupport),
      ],
      child: const MaterialApp(home: TrackingScreen(token: 'tok-1')),
    );

void main() {
  testWidgets('shows plan title, status, usage ring, validity, and QR',
      (tester) async {
    final api = _FakeTrackingApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(api.lastToken, 'tok-1');
    expect(find.text('Saudi Arabia 1GB 7Days'), findsOneWidget);
    expect(find.text('IN_USE'), findsOneWidget);
    expect(find.text('1.40 GB'), findsOneWidget);
    expect(find.text('14 days left'), findsOneWidget);
    expect(find.byType(EsimQr), findsOneWidget);
  });

  testWidgets('shows the manual install codes, each copyable', (tester) async {
    await tester.pumpWidget(_app(_FakeTrackingApi()));
    await tester.pumpAndSettle();

    expect(find.text('smdp.example.invalid'), findsOneWidget);
    expect(find.text('EXAMPLE-ACTIVATION'), findsOneWidget);
    expect(find.text(_lpa), findsOneWidget);
  });

  testWidgets(
      'an invalid token shows the real server error and Support contacts',
      (tester) async {
    await tester.pumpWidget(_app(_FakeTrackingApi(
        result: const ApiException(statusCode: 404, message: 'Not found'))));
    await tester.pumpAndSettle();

    expect(find.text('Not found'), findsOneWidget);
    expect(find.textContaining('support@triptel.co'), findsOneWidget);
  });

  testWidgets('no Support contact box when settings have none', (tester) async {
    await tester.pumpWidget(_app(
      _FakeTrackingApi(
          result: const ApiException(statusCode: 404, message: 'Not found')),
      withSupportSettings: false,
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.support_agent_outlined), findsNothing);
  });
}
