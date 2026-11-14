import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/checkout/application/url_launcher_provider.dart';
import 'package:triptel/features/checkout/data/models/order.dart';
import 'package:triptel/features/checkout/presentation/purchase_success_screen.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';

const _lpa = r'LPA:1$smdp.example.invalid$ACTIVATION-CODE';

Order _orderWith(EsimProfile? esimProfile) => Order(
      id: 'order-1',
      orderNo: 'ORD-TEST-1',
      productId: 'product-1',
      totalAmount: const Money(90),
      discountAmount: const Money(0),
      status: 'COMPLETED',
      esimProfile: esimProfile,
    );

const _profile = EsimProfile(
  id: 'esim-1',
  iccid: '00000000000000000000',
  lpaString: _lpa,
  qrCodeData: _lpa,
  smdpAddress: 'smdp.example.invalid',
  status: 'RELEASED',
);

Widget _app({
  required Order order,
  EsimVerdict verdict = const EsimVerdict(
      kind: EsimVerdictKind.supported, deviceLabel: 'Test', reason: ''),
  List<String>? launchedUrls,
  bool launchResult = true,
}) =>
    ProviderScope(
      overrides: [
        esimVerdictProvider.overrideWith((ref) async => verdict),
        urlLauncherProvider.overrideWithValue((url) async {
          launchedUrls?.add(url.toString());
          return launchResult;
        }),
      ],
      child: MaterialApp(home: PurchaseSuccessScreen(order: order)),
    );

void main() {
  testWidgets('shows the order number and a QR for a completed order',
      (tester) async {
    await tester.pumpWidget(_app(order: _orderWith(_profile)));
    await tester.pumpAndSettle();

    expect(find.textContaining('ORD-TEST-1'), findsOneWidget);
    expect(find.text('Your eSIM is ready!'), findsOneWidget);
  });

  testWidgets(
      'supported device: shows the 1-tap install button, tapping it launches '
      "the platform's install URL", (tester) async {
    final launched = <String>[];
    await tester
        .pumpWidget(_app(order: _orderWith(_profile), launchedUrls: launched));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('one-tap-install-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('one-tap-install-button')));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single, contains('esim_qrcode_provisioning'));
  });

  testWidgets(
      'unsupported device: no install button, shows the saved-for-later note',
      (tester) async {
    await tester.pumpWidget(_app(
      order: _orderWith(_profile),
      verdict: const EsimVerdict(
          kind: EsimVerdictKind.notSupported, deviceLabel: 'Test', reason: ''),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('one-tap-install-button')), findsNothing);
    expect(find.textContaining("isn't eSIM-compatible"), findsOneWidget);
  });

  testWidgets('unknown compatibility: no install button, shows the softer note',
      (tester) async {
    await tester.pumpWidget(_app(
      order: _orderWith(_profile),
      verdict: const EsimVerdict(
          kind: EsimVerdictKind.unknown, deviceLabel: 'Test', reason: ''),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('one-tap-install-button')), findsNothing);
    expect(find.textContaining("couldn't confirm"), findsOneWidget);
  });

  testWidgets(
      'copy activation code copies the real LPA string to the clipboard',
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

    await tester.pumpWidget(_app(order: _orderWith(_profile)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('copy-activation-code-button')));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single.text, _lpa);
    expect(find.text('Activation code copied.'), findsOneWidget);
  });

  testWidgets(
      'no esim_profile (defensive): no QR/install, but Go to My eSIMs works',
      (tester) async {
    await tester.pumpWidget(_app(order: _orderWith(null)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('one-tap-install-button')), findsNothing);
    expect(find.byKey(const ValueKey('go-to-my-esims-button')), findsOneWidget);
  });

  testWidgets('"Go to My eSIMs" navigates to /my-esims', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ProviderScope(
          overrides: [
            esimVerdictProvider.overrideWith((ref) async => const EsimVerdict(
                kind: EsimVerdictKind.supported,
                deviceLabel: 'Test',
                reason: '')),
            urlLauncherProvider.overrideWithValue((url) async => true),
          ],
          child: PurchaseSuccessScreen(order: _orderWith(_profile)),
        ),
      ),
      GoRoute(
        path: '/my-esims',
        builder: (context, state) =>
            const Scaffold(body: Text('My eSIMs screen')),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('go-to-my-esims-button')));
    await tester.pumpAndSettle();

    expect(find.text('My eSIMs screen'), findsOneWidget);
  });

  testWidgets('a failed install launch shows an error snack, never crashes',
      (tester) async {
    await tester
        .pumpWidget(_app(order: _orderWith(_profile), launchResult: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('one-tap-install-button')));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open the install link."), findsOneWidget);
  });
}
