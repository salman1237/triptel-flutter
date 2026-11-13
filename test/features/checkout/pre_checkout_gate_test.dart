import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/checkout/presentation/pre_checkout_gate.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/compatibility/presentation/supported_devices_screen.dart';

const _verdict = EsimVerdict(
  kind: EsimVerdictKind.supported,
  deviceLabel: 'Pixel 8',
  reason: 'eSIM is supported and enabled on this device.',
);

Widget _appWithGateButton(EsimVerdict verdict,
    {required VoidCallback onContinue}) {
  return ProviderScope(
    overrides: [
      esimVerdictProvider.overrideWith((ref) async => verdict),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => runPreCheckoutCompatibilityGate(
                  context,
                  ref,
                  onContinue: onContinue,
                ),
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/compatibility/devices',
          builder: (context, state) => const SupportedDevicesScreen(),
        ),
      ]),
    ),
  );
}

void main() {
  testWidgets('supported: calls onContinue immediately, no dialog',
      (tester) async {
    var continued = false;
    await tester.pumpWidget(
        _appWithGateButton(_verdict, onContinue: () => continued = true));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(continued, isTrue);
    expect(
        find.byKey(const ValueKey('buy-now-use-later-dialog')), findsNothing);
  });

  testWidgets(
      'not supported: shows the Buy Now, Use Later dialog instead of '
      'calling onContinue right away', (tester) async {
    var continued = false;
    await tester.pumpWidget(_appWithGateButton(
      _verdict.copyWithKind(EsimVerdictKind.notSupported),
      onContinue: () => continued = true,
    ));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(continued, isFalse);
    expect(
        find.byKey(const ValueKey('buy-now-use-later-dialog')), findsOneWidget);
    expect(find.text('Buy Now, Use Later!'), findsOneWidget);
  });

  testWidgets(
      'not supported dialog: tapping Continue dismisses it and calls '
      'onContinue', (tester) async {
    var continued = false;
    await tester.pumpWidget(_appWithGateButton(
      _verdict.copyWithKind(EsimVerdictKind.notSupported),
      onContinue: () => continued = true,
    ));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('gate-dialog-primary')));
    await tester.pumpAndSettle();

    expect(continued, isTrue);
    expect(
        find.byKey(const ValueKey('buy-now-use-later-dialog')), findsNothing);
  });

  testWidgets(
      'not supported dialog: tapping "View Supported Devices" navigates '
      'there and never calls onContinue', (tester) async {
    var continued = false;
    await tester.pumpWidget(_appWithGateButton(
      _verdict.copyWithKind(EsimVerdictKind.notSupported),
      onContinue: () => continued = true,
    ));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Supported Devices'));
    await tester.pumpAndSettle();

    expect(continued, isFalse);
    expect(find.byType(SupportedDevicesScreen), findsOneWidget);
  });

  testWidgets(
      'not supported dialog: tapping Cancel dismisses it without calling '
      'onContinue', (tester) async {
    var continued = false;
    await tester.pumpWidget(_appWithGateButton(
      _verdict.copyWithKind(EsimVerdictKind.notSupported),
      onContinue: () => continued = true,
    ));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(continued, isFalse);
    expect(
        find.byKey(const ValueKey('buy-now-use-later-dialog')), findsNothing);
  });

  testWidgets(
      'unknown: shows the softer note, with no "View Supported Devices" '
      'option since nothing is confirmed', (tester) async {
    var continued = false;
    await tester.pumpWidget(_appWithGateButton(
      _verdict.copyWithKind(EsimVerdictKind.unknown),
      onContinue: () => continued = true,
    ));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(continued, isFalse);
    expect(find.byKey(const ValueKey('unknown-compatibility-dialog')),
        findsOneWidget);
    expect(find.text('View Supported Devices'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gate-dialog-primary')));
    await tester.pumpAndSettle();
    expect(continued, isTrue);
  });

  testWidgets('a verdict-check failure never blocks: calls onContinue directly',
      (tester) async {
    var continued = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esimVerdictProvider
              .overrideWith((ref) async => throw Exception('channel error')),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => runPreCheckoutCompatibilityGate(
                    context,
                    ref,
                    onContinue: () => continued = true,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(continued, isTrue);
  });
}

extension on EsimVerdict {
  EsimVerdict copyWithKind(EsimVerdictKind kind) => EsimVerdict(
        kind: kind,
        deviceLabel: deviceLabel,
        reason: reason,
      );
}
