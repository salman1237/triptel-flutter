import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/presentation/home_screen.dart';
import 'package:triptel/features/esims/application/esim_status_providers.dart';
import 'package:triptel/features/esims/application/my_esims_providers.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

const _countries = [
  Country(
    id: 107,
    iso2: 'JP',
    nameEn: 'Japan',
    isActive: true,
    slug: 'japan',
    flagUrl: 'https://flagcdn.com/w80/jp.png',
  ),
  Country(
      id: 18,
      iso2: 'BD',
      nameEn: 'Bangladesh',
      isActive: true,
      slug: 'bangladesh'),
];

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

const _token = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: false,
);

MyEsim _esim({String id = 'esim-1', String status = 'ACTIVE'}) => MyEsim(
      id: id,
      orderNo: 'ORD-TEST-1',
      productTitle: 'Japan 1GB 7Days',
      dataAmountGb: 1,
      isUnlimited: false,
      validityDays: 7,
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      status: status,
      isMockFallback: false,
      createdAt: DateTime.utc(2026, 11, 1),
      activatedAt: DateTime.utc(2026, 11, 1),
      expiresAt: DateTime.utc(2026, 11, 20),
      isBeneficiary: false,
    );

EsimStatus _status({String esimId = 'esim-1'}) => EsimStatus(
      esimId: esimId,
      orderNo: 'ORD-TEST-1',
      product: const EsimStatusProduct(
        title: 'Japan 1GB 7Days',
        validityDays: 7,
        isUnlimited: false,
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
      usage: const EsimUsageInfo(
        usedFormatted: '300.00 MB',
        allowanceMb: 1024,
        remainingMb: 724,
        remainingFormatted: '724.00 MB',
        usedPct: 30,
        isUnlimited: false,
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

Widget _app({
  AsyncValue<List<Country>> popular =
      const AsyncData<List<Country>>(_countries),
  AuthState auth = const AuthUnauthenticated(),
  List<MyEsim> esims = const [],
  EsimStatus? status,
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/my-esims',
          builder: (context, state) => const Text('my-esims-placeholder')),
      GoRoute(
        path: '/my-esims/:id',
        builder: (context, state) =>
            Text('esim-detail-placeholder-${state.pathParameters['id']}'),
      ),
      GoRoute(
          path: '/wallet',
          builder: (context, state) => const Text('wallet-placeholder')),
      GoRoute(
        path: '/explore/:slug',
        builder: (context, state) =>
            Text('plans-placeholder-${state.pathParameters['slug']}'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      popularCountriesProvider.overrideWith((ref) {
        return switch (popular) {
          AsyncData(:final value) => Future.value(value),
          AsyncError(:final error) => Future<List<Country>>.error(error),
          _ => Completer<List<Country>>().future,
        };
      }),
      allCountriesProvider.overrideWith((ref) async => _countries),
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(auth)),
      myEsimsProvider.overrideWith((ref) async => esims),
      if (status != null)
        esimStatusProvider(status.esimId).overrideWith((ref) async => status),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows popular destinations from the provider', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Bangladesh'), findsOneWidget);
  });

  testWidgets('2026-11-17 UI refresh: the hero shows the real branding tagline',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Travel smart.\nStay connected.'), findsOneWidget);
  });

  testWidgets(
      "there's no 'My eSIMs' or 'Top up' quick action in the hero -- both "
      'would just duplicate an existing bottom tab today', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('My eSIMs'), findsNothing);
    expect(find.text('Top up'), findsNothing);
    expect(find.text('Buy data'), findsOneWidget);
  });

  testWidgets('Buy data opens the FR-202 explore sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buy data'));
    await tester.pumpAndSettle();

    expect(find.text('Search countries'), findsOneWidget);
  });

  testWidgets('tapping the search pill also opens the explore sheet',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-search-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Search countries'), findsOneWidget);
  });

  testWidgets(
      "a popular-destination row tap navigates to FR-204's plans screen",
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Japan'));
    await tester.pumpAndSettle();

    expect(find.text('plans-placeholder-japan'), findsOneWidget);
  });

  testWidgets('shows a retry error state when the provider throws',
      (tester) async {
    await tester
        .pumpWidget(_app(popular: AsyncError('boom', StackTrace.empty)));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load popular destinations."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while the provider resolves',
      (tester) async {
    await tester.pumpWidget(_app(popular: const AsyncLoading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'FR-201b: a signed-in user with an ACTIVE eSIM sees the real usage '
      'card instead of the hero tagline', (tester) async {
    await tester.pumpWidget(_app(
      auth: const AuthAuthenticated(_token),
      esims: [_esim()],
      status: _status(),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-usage-card')), findsOneWidget);
    expect(find.text('Travel smart.\nStay connected.'), findsNothing);
    expect(find.text('Japan 1GB 7Days'), findsOneWidget);
  });

  testWidgets('tapping the real usage card opens that eSIM\'s detail screen',
      (tester) async {
    await tester.pumpWidget(_app(
      auth: const AuthAuthenticated(_token),
      esims: [_esim(id: 'esim-42')],
      status: _status(esimId: 'esim-42'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-usage-card')));
    await tester.pumpAndSettle();

    expect(find.text('esim-detail-placeholder-esim-42'), findsOneWidget);
  });

  testWidgets(
      'a signed-in user with no ACTIVE/INSTALLED eSIM still sees the '
      'default hero', (tester) async {
    await tester.pumpWidget(_app(
      auth: const AuthAuthenticated(_token),
      esims: [_esim(status: 'RELEASED')],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Travel smart.\nStay connected.'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-usage-card')), findsNothing);
  });

  testWidgets(
      'a signed-in user with no eSIMs at all still sees the default hero',
      (tester) async {
    await tester.pumpWidget(_app(auth: const AuthAuthenticated(_token)));
    await tester.pumpAndSettle();

    expect(find.text('Travel smart.\nStay connected.'), findsOneWidget);
  });
}
