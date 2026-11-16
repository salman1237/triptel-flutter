import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/install/url_launcher_provider.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/esims/application/esim_status_providers.dart';
import 'package:triptel/features/esims/data/esim_status_api.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/esims/data/models/topup_option.dart';
import 'package:triptel/features/esims/presentation/esim_detail_screen.dart';
import 'package:triptel/core/money/money.dart';

const _lpa = r'LPA:1$smdp.example.invalid$ACTIVATION-CODE';

EsimStatus _status({
  String label = 'Not installed yet',
  bool isUnlimited = false,
  double usedPct = 0,
  DateTime? activatedAt,
  DateTime? expiresAt,
  String? telemetryError,
  String lpaString = _lpa,
  String smdpAddress = 'smdp.example.invalid',
  String? matchingId = 'ACTIVATION-CODE',
  String esimStatus = 'RELEASED',
  List<Map<String, dynamic>> history = const [],
  List<Map<String, dynamic>> dailyBreakdown = const [],
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
      lpaString: lpaString,
      qrCodeData: lpaString,
      smdpAddress: smdpAddress,
      matchingId: matchingId,
      esimStatus: esimStatus,
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
      history: history,
      dailyBreakdown: dailyBreakdown,
    );

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FakeEsimStatusApi implements EsimStatusApi {
  _FakeEsimStatusApi(this._initial,
      {Object? refreshResult,
      List<TopupOption> topupOptions = const [],
      this.topupError})
      : _refreshResult = refreshResult,
        _topupOptions = topupOptions;
  final EsimStatus _initial;
  final Object? _refreshResult; // EsimStatus or Exception.
  final List<TopupOption> _topupOptions;
  final Exception? topupError;
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

  @override
  Future<List<TopupOption>> getTopupOptions(String esimId) async {
    final error = topupError;
    if (error != null) throw error;
    return _topupOptions;
  }
}

Widget _app(
  EsimStatusApi api, {
  EsimVerdict verdict = const EsimVerdict(
      kind: EsimVerdictKind.supported, deviceLabel: 'Test', reason: ''),
  List<String>? launchedUrls,
  bool launchResult = true,
}) =>
    ProviderScope(
      overrides: [
        esimStatusApiProvider.overrideWithValue(api),
        esimVerdictProvider.overrideWith((ref) async => verdict),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
        urlLauncherProvider.overrideWithValue((url) async {
          launchedUrls?.add(url.toString());
          return launchResult;
        }),
      ],
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

  group('FR-404: install section', () {
    testWidgets('renders the QR code', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
      await tester.pumpAndSettle();

      expect(find.byType(EsimQr), findsOneWidget);
    });

    testWidgets(
        'supported device: shows the 1-tap install button, tapping it '
        "launches the platform's install URL", (tester) async {
      final launched = <String>[];
      await tester.pumpWidget(
          _app(_FakeEsimStatusApi(_status()), launchedUrls: launched));
      await tester.pumpAndSettle();

      final installButton =
          find.byKey(const ValueKey('esim-one-tap-install-button'));
      expect(installButton, findsOneWidget);

      await tester.ensureVisible(installButton);
      await tester.tap(installButton);
      await tester.pumpAndSettle();

      expect(launched, hasLength(1));
      expect(launched.single, contains('esim_qrcode_provisioning'));
    });

    testWidgets(
        'unsupported device: no install button, shows the fallback-to-codes '
        'explanation', (tester) async {
      await tester.pumpWidget(_app(
        _FakeEsimStatusApi(_status()),
        verdict: const EsimVerdict(
            kind: EsimVerdictKind.notSupported,
            deviceLabel: 'Test',
            reason: ''),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('esim-one-tap-install-button')),
          findsNothing);
      expect(find.byKey(const ValueKey('esim-install-explanation')),
          findsOneWidget);
    });

    testWidgets('shows the "install only once" warning', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('only install this eSIM once'), findsOneWidget);
    });

    testWidgets(
        'shows SM-DP+ address, matching ID, and the LPA code, each copyable',
        (tester) async {
      final copied = <ClipboardData>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
                ClipboardData(text: (call.arguments as Map)['text'] as String));
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
      await tester.pumpAndSettle();

      expect(find.text('smdp.example.invalid'), findsOneWidget);
      expect(find.text('ACTIVATION-CODE'), findsOneWidget);
      expect(find.text(_lpa), findsOneWidget);

      final smdpCopy = find.byKey(const ValueKey('esim-copy-SM-DP+ address'));
      await tester.ensureVisible(smdpCopy);
      await tester.tap(smdpCopy);
      await tester.pumpAndSettle();
      expect(copied.last.text, 'smdp.example.invalid');
      expect(find.text('SM-DP+ address copied.'), findsOneWidget);

      final matchingIdCopy =
          find.byKey(const ValueKey('esim-copy-Matching ID'));
      await tester.ensureVisible(matchingIdCopy);
      await tester.tap(matchingIdCopy);
      await tester.pumpAndSettle();
      expect(copied.last.text, 'ACTIVATION-CODE');

      final lpaCopy =
          find.byKey(const ValueKey('esim-copy-Activation code (LPA)'));
      await tester.ensureVisible(lpaCopy);
      await tester.tap(lpaCopy);
      await tester.pumpAndSettle();
      expect(copied.last.text, _lpa);
    });

    testWidgets('no matching ID -> that row is hidden entirely',
        (tester) async {
      await tester
          .pumpWidget(_app(_FakeEsimStatusApi(_status(matchingId: null))));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('esim-copy-Matching ID')), findsNothing);
    });

    testWidgets('tapping the setup guide link launches the web guide URL',
        (tester) async {
      final launched = <String>[];
      await tester.pumpWidget(
          _app(_FakeEsimStatusApi(_status()), launchedUrls: launched));
      await tester.pumpAndSettle();

      final guideLink = find.byKey(const ValueKey('esim-setup-guide-link'));
      await tester.ensureVisible(guideLink);
      await tester.tap(guideLink);
      await tester.pumpAndSettle();

      expect(launched, hasLength(1));
      expect(launched.single, contains('guides/esim-setup-guide'));
    });

    testWidgets('a failed install launch shows an error snack, never crashes',
        (tester) async {
      await tester
          .pumpWidget(_app(_FakeEsimStatusApi(_status()), launchResult: false));
      await tester.pumpAndSettle();

      final installButton =
          find.byKey(const ValueKey('esim-one-tap-install-button'));
      await tester.ensureVisible(installButton);
      await tester.tap(installButton);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open the install link."), findsOneWidget);
    });
  });

  group('FR-405: lifecycle banners', () {
    for (final status in ['SUSPENDED', 'REVOKED', 'CANCELLED', 'EXPIRED']) {
      testWidgets(
          '$status shows a lifecycle banner and hides the entire install '
          'section', (tester) async {
        await tester
            .pumpWidget(_app(_FakeEsimStatusApi(_status(esimStatus: status))));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('esim-lifecycle-banner')),
            findsOneWidget);
        expect(find.textContaining('install and top-up are unavailable'),
            findsOneWidget);
        expect(find.byType(EsimQr), findsNothing);
        expect(find.byKey(const ValueKey('esim-one-tap-install-button')),
            findsNothing);
        expect(find.byKey(const ValueKey('esim-install-explanation')),
            findsNothing);
        expect(find.byKey(const ValueKey('esim-copy-SM-DP+ address')),
            findsNothing);
        expect(
            find.byKey(const ValueKey('esim-setup-guide-link')), findsNothing);
      });
    }

    for (final status in ['ALLOCATED', 'RELEASED', 'INSTALLED', 'ACTIVE']) {
      testWidgets('$status shows no lifecycle banner, install section intact',
          (tester) async {
        await tester
            .pumpWidget(_app(_FakeEsimStatusApi(_status(esimStatus: status))));
        await tester.pumpAndSettle();

        expect(
            find.byKey(const ValueKey('esim-lifecycle-banner')), findsNothing);
        expect(find.byType(EsimQr), findsOneWidget);
      });
    }

    testWidgets(
        'the usage ring, usage status label, and refresh button stay '
        'visible even when the lifecycle banner is shown', (tester) async {
      await tester
          .pumpWidget(_app(_FakeEsimStatusApi(_status(esimStatus: 'EXPIRED'))));
      await tester.pumpAndSettle();

      expect(find.byType(UsageRing), findsOneWidget);
      expect(find.byKey(const ValueKey('esim-refresh-button')), findsOneWidget);
    });
  });

  group('FR-406: history', () {
    testWidgets('both empty -> no history section at all', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
      await tester.pumpAndSettle();

      expect(find.text('Daily usage'), findsNothing);
      expect(find.text('Install history'), findsNothing);
    });

    testWidgets(
        'a non-empty daily breakdown shows the "Daily usage" '
        'section with one line per entry', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status(
        dailyBreakdown: const [
          {'date': '2026-11-11', 'used_mb': '120'},
          {'date': '2026-11-12', 'used_mb': '80'},
        ],
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Daily usage'), findsOneWidget);
      expect(find.text('date: 2026-11-11, used_mb: 120'), findsOneWidget);
      expect(find.text('date: 2026-11-12, used_mb: 80'), findsOneWidget);
    });

    testWidgets(
        'a non-empty history shows the "Install history" section, eid '
        'excluded from the displayed line', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status(
        history: const [
          {'event': 'ACTIVATED', 'eid': 'should-not-be-shown'},
        ],
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Install history'), findsOneWidget);
      expect(find.text('event: ACTIVATED'), findsOneWidget);
      expect(find.textContaining('should-not-be-shown'), findsNothing);
    });

    testWidgets(
        'only daily breakdown present -> no "Install history" '
        'heading shown', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status(
        dailyBreakdown: const [
          {'date': '2026-11-11', 'used_mb': '120'},
        ],
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Daily usage'), findsOneWidget);
      expect(find.text('Install history'), findsNothing);
    });

    testWidgets(
        'the history section still shows under a terminal lifecycle '
        'status (independent of the install-section gate)', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status(
        esimStatus: 'EXPIRED',
        history: const [
          {'event': 'ACTIVATED'},
        ],
      ))));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('esim-lifecycle-banner')), findsOneWidget);
      expect(find.text('Install history'), findsOneWidget);
    });
  });

  group('FR-407: top-up options', () {
    testWidgets('empty list -> no top-up section at all', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(_status())));
      await tester.pumpAndSettle();

      expect(find.text('Top up'), findsNothing);
    });

    testWidgets(
        'a non-empty list shows the "Top up" section with one row per '
        'option, title/validity/price', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(
        _status(),
        topupOptions: const [
          TopupOption(
            packageCode: 'TOPUP_JC063',
            title: 'Japan 1GB 7Days',
            dataAmountGb: 1.0,
            validityDays: 7,
            retailPrice: Money(210),
          ),
          TopupOption(
            packageCode: 'TOPUP_JC064',
            title: 'Japan 3GB 15Days',
            dataAmountGb: 3.0,
            validityDays: 15,
            retailPrice: Money(510),
          ),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text('Top up'), findsOneWidget);
      expect(find.text('Japan 1GB 7Days'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('€2.10'), findsOneWidget);
      expect(find.text('Japan 3GB 15Days'), findsOneWidget);
      expect(find.text('15 days'), findsOneWidget);
      expect(find.text('€5.10'), findsOneWidget);
    });

    testWidgets('tapping an option shows the coming-soon note, not a dead end',
        (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(
        _status(),
        topupOptions: const [
          TopupOption(
            packageCode: 'TOPUP_JC063',
            title: 'Japan 1GB 7Days',
            dataAmountGb: 1.0,
            validityDays: 7,
            retailPrice: Money(210),
          ),
        ],
      )));
      await tester.pumpAndSettle();

      final optionFinder =
          find.byKey(const ValueKey('topup-option-TOPUP_JC063'));
      await tester.ensureVisible(optionFinder);
      await tester.tap(optionFinder);
      await tester.pump();

      expect(find.text('Top-up purchase is coming soon.'), findsOneWidget);
    });

    testWidgets(
        'a non-empty list is hidden under a terminal lifecycle status '
        '(Rules.md: lifecycle disables install AND top-up)', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(
        _status(esimStatus: 'EXPIRED'),
        topupOptions: const [
          TopupOption(
            packageCode: 'TOPUP_JC063',
            title: 'Japan 1GB 7Days',
            dataAmountGb: 1.0,
            validityDays: 7,
            retailPrice: Money(210),
          ),
        ],
      )));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('esim-lifecycle-banner')), findsOneWidget);
      expect(find.text('Top up'), findsNothing);
    });

    testWidgets(
        'a topup-options load error silently hides the section rather than '
        'crashing (the rest of the screen still renders)', (tester) async {
      await tester.pumpWidget(_app(_FakeEsimStatusApi(
        _status(),
        topupError: Exception('network error'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Top up'), findsNothing);
      expect(find.text('Japan 100MB 7Days'), findsOneWidget);
    });
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
}
