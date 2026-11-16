import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/esims/application/esim_status_providers.dart';
import 'package:triptel/features/esims/data/esim_status_api.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/esims/presentation/esim_detail_screen.dart';

EsimStatus _status({
  String label = 'Not installed yet',
  bool isUnlimited = false,
  double usedPct = 0,
  DateTime? activatedAt,
  DateTime? expiresAt,
  String? telemetryError,
}) =>
    EsimStatus(
      esimId: 'esim-1',
      orderNo: 'ORD-TEST-1',
      product: EsimStatusProduct(
        title: 'Japan 100MB 7Days',
        validityDays: 7,
        isUnlimited: isUnlimited,
        dataAmountGb: 0.1,
      ),
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      matchingId: null,
      esimStatus: 'RELEASED',
      status: EsimStatusInfo(
        label: label,
        code: 0,
        isInstalled: false,
        isActivated: false,
        deviceModel: null,
      ),
      usage: EsimUsageInfo(
        usedFormatted: '0.00 MB',
        allowanceMb: isUnlimited ? null : 100,
        remainingMb: isUnlimited ? null : 100,
        remainingFormatted: isUnlimited ? 'Unlimited' : '100.00 MB',
        usedPct: isUnlimited ? null : usedPct,
        isUnlimited: isUnlimited,
      ),
      validity: EsimValidityInfo(
        days: 7,
        activatedAt: activatedAt,
        expiresAt: expiresAt,
        note: '',
      ),
      shareUrl: null,
      telemetry: EsimTelemetryInfo(
        fetchedAt:
            telemetryError != null ? DateTime.utc(2026, 11, 16, 17) : null,
        error: telemetryError,
        available: true,
      ),
    );

class _FakeEsimStatusApi implements EsimStatusApi {
  _FakeEsimStatusApi(this._initial, {Object? refreshResult})
      : _refreshResult = refreshResult;
  final EsimStatus _initial;
  final Object? _refreshResult; // EsimStatus or Exception.
  var refreshCalls = 0;

  @override
  Future<EsimStatus> getStatus(String esimId) async => _initial;

  @override
  Future<EsimStatus> refresh(String esimId) async {
    refreshCalls++;
    final result = _refreshResult;
    if (result is Exception) throw result;
    return result as EsimStatus? ?? _initial;
  }
}

Widget _app(EsimStatusApi api) => ProviderScope(
      overrides: [esimStatusApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: EsimDetailScreen(esimId: 'esim-1')),
    );

void main() {
  testWidgets('shows plan title, status label, usage ring, and validity note',
      (tester) async {
    await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
    await tester.pumpAndSettle();

    expect(find.text('Japan 100MB 7Days'), findsOneWidget);
    expect(find.text('Not installed yet'), findsOneWidget);
    expect(find.text('100.00 MB'), findsOneWidget);
    expect(find.text('Validity starts on install'), findsOneWidget);
  });

  testWidgets('unlimited plan shows "Unlimited" with no progress fraction',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeEsimStatusApi(_status(isUnlimited: true))));
    await tester.pumpAndSettle();

    expect(find.text('Unlimited'), findsOneWidget);
  });

  testWidgets('a telemetry error shows the stale-usage banner', (tester) async {
    await tester.pumpWidget(_app(
        _FakeEsimStatusApi(_status(telemetryError: 'supplier unreachable'))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Live usage temporarily unavailable'),
        findsOneWidget);
  });

  testWidgets('no telemetry error shows no banner', (tester) async {
    await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
    await tester.pumpAndSettle();

    expect(find.textContaining('temporarily unavailable'), findsNothing);
  });

  testWidgets(
      'manual refresh calls POST /refresh, updates the display, then '
      'disables the button for the cooldown', (tester) async {
    final api = _FakeEsimStatusApi(
      _status(label: 'Not installed yet'),
      refreshResult: _status(label: 'Installed'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Not installed yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('esim-refresh-button')));
    await tester.pumpAndSettle();

    expect(api.refreshCalls, 1);
    expect(find.text('Installed'), findsOneWidget);

    // Immediately after a refresh, the button must be disabled (cooldown).
    final button = tester
        .widget<PillButton>(find.byKey(const ValueKey('esim-refresh-button')));
    expect(button.onPressed, isNull);
  });

  testWidgets('a refresh error shows the real server message, never crashes',
      (tester) async {
    final api = _FakeEsimStatusApi(
      _status(),
      refreshResult: const ApiException(
          statusCode: 429, message: 'Too many refresh attempts'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('esim-refresh-button')));
    await tester.pumpAndSettle();

    expect(find.text('Too many refresh attempts'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(_ThrowingEsimStatusApi()));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this eSIM."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _ThrowingEsimStatusApi implements EsimStatusApi {
  @override
  Future<EsimStatus> getStatus(String esimId) async =>
      throw Exception('network error');

  @override
  Future<EsimStatus> refresh(String esimId) async =>
      throw Exception('network error');
}
