import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/esims/application/my_esims_providers.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';
import 'package:triptel/features/esims/data/my_esims_api.dart';
import 'package:triptel/features/esims/presentation/my_esims_screen.dart';

MyEsim _esim(String id,
        {String status = 'RELEASED', bool isBeneficiary = false}) =>
    MyEsim(
      id: id,
      orderNo: 'ORD-$id',
      productTitle: 'Japan 100MB 7Days',
      dataAmountGb: 0.1,
      isUnlimited: false,
      validityDays: 7,
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      status: status,
      isMockFallback: false,
      createdAt: DateTime.utc(2026, 1, 1),
      activatedAt: null,
      expiresAt: null,
      isBeneficiary: isBeneficiary,
    );

class _FakeMyEsimsApi implements MyEsimsApi {
  _FakeMyEsimsApi(this._result);
  final Object _result; // List<MyEsim> or Exception.
  var calls = 0;

  @override
  Future<List<MyEsim>> getMyEsims() async {
    calls++;
    final result = _result;
    if (result is Exception) throw result;
    return result as List<MyEsim>;
  }
}

Widget _app(Object apiResult) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => ProviderScope(
        overrides: [
          myEsimsApiProvider.overrideWithValue(_FakeMyEsimsApi(apiResult)),
        ],
        child: const MyEsimsScreen(),
      ),
    ),
    GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Home screen'))),
    GoRoute(
      path: '/my-esims/:id',
      builder: (context, state) =>
          Scaffold(body: Text('eSIM detail for ${state.pathParameters['id']}')),
    ),
  ]);
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets(
      'shows a card per eSIM with title, chip, data/validity, ownership',
      (tester) async {
    await tester.pumpWidget(_app([
      _esim('1', status: 'RELEASED', isBeneficiary: true),
      _esim('2', status: 'ACTIVE'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Japan 100MB 7Days'), findsNWidgets(2));
    expect(find.text('Ready to install'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Bought for me'), findsOneWidget);
    expect(find.text('Bought by me'), findsOneWidget);
    expect(find.textContaining('100 MB'), findsNWidgets(2));
    expect(find.textContaining('Validity starts on install'), findsNWidgets(2));
  });

  testWidgets('tapping a card navigates to /my-esims/<id>', (tester) async {
    await tester.pumpWidget(_app([_esim('42')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('esim-card-42')));
    await tester.pumpAndSettle();

    expect(find.text('eSIM detail for 42'), findsOneWidget);
  });

  testWidgets('empty state shows the explore CTA and navigates to /home',
      (tester) async {
    await tester.pumpWidget(_app(const <MyEsim>[]));
    await tester.pumpAndSettle();

    expect(find.textContaining("haven't bought"), findsOneWidget);
    await tester.tap(find.text('Explore destinations'));
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(Exception('Network error')));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your eSIMs."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('pull to refresh re-fetches the list', (tester) async {
    final api = _FakeMyEsimsApi([_esim('1')]);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ProviderScope(
          overrides: [myEsimsApiProvider.overrideWithValue(api)],
          child: const MyEsimsScreen(),
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(api.calls, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(api.calls, 2);
  });
}
