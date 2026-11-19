import 'dart:async';
import 'dart:typed_data';

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
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_attachment.dart';
import 'package:triptel/features/support/data/models/support_category.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';

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

final _farPast = DateTime.utc(2020, 1, 1);
final _farFuture = DateTime.utc(2099, 1, 1);

MyEsim _esim({String id = 'esim-1', bool activated = true}) => MyEsim(
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
      // Deliberately a stale 'RELEASED' even for a qualifying eSIM, mirroring
      // the real account this was verified against -- activeEsimForHomeCard
      // must key off activatedAt/expiresAt, never status.
      status: 'RELEASED',
      isMockFallback: false,
      createdAt: _farPast,
      activatedAt: activated ? _farPast : null,
      expiresAt: activated ? _farFuture : null,
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

/// FR-C904's own fake -- not a mocktail Mock, same hand-written pattern as
/// every other `SupportApi` fake in this project's support tests.
class _FakeSupportApi implements SupportApi {
  _FakeSupportApi({
    this.tickets = const [],
    this.getTicketsError,
    this.getTicketsDelay,
  });
  List<SupportTicket> tickets;
  ApiException? getTicketsError;
  Duration? getTicketsDelay;
  SupportTicket? lastCreated;
  int createTicketCalls = 0;

  @override
  Future<List<SupportTicket>> getTickets() async {
    if (getTicketsDelay != null) await Future.delayed(getTicketsDelay!);
    if (getTicketsError != null) throw getTicketsError!;
    return tickets;
  }

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  }) async {
    final created = SupportTicket(
      id: 'new-ticket',
      reference: 'TKT-NEW',
      subject: subject,
      category: category,
      status: 'OPEN',
    );
    createTicketCalls++;
    lastCreated = created;
    return created;
  }

  @override
  Future<SupportTicket> getTicket(String id) => throw UnimplementedError();

  @override
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
    String? sharedOrderId,
    String? sharedProductId,
  }) =>
      throw UnimplementedError();

  @override
  Future<SupportTicket> closeTicket(String id) => throw UnimplementedError();

  @override
  Future<Uint8List> downloadAttachment(SupportAttachment attachment) =>
      throw UnimplementedError();

  @override
  Future<List<SupportCategory>> getCategories() => throw UnimplementedError();
}

Widget _app({
  AsyncValue<List<Country>> popular =
      const AsyncData<List<Country>>(_countries),
  AuthState auth = const AuthUnauthenticated(),
  List<MyEsim> esims = const [],
  EsimStatus? status,
  SupportApi? supportApi,
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
      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            Text('support-thread-placeholder-${state.pathParameters['id']}'),
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
      if (supportApi != null) supportApiProvider.overrideWithValue(supportApi),
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
      'a signed-in user with no genuinely-activated eSIM still sees the '
      'default hero -- even one whose status still says RELEASED (the '
      'real, known-stale case) but was never actually activated',
      (tester) async {
    await tester.pumpWidget(_app(
      auth: const AuthAuthenticated(_token),
      esims: [_esim(activated: false)],
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

  group('FR-C904: Chat with Support', () {
    testWidgets('is hidden when signed out', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('home-chat-with-support')), findsNothing);
    });

    testWidgets('is visible when signed in', (tester) async {
      await tester.pumpWidget(_app(auth: const AuthAuthenticated(_token)));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('home-chat-with-support')), findsOneWidget);
    });

    testWidgets(
        'tapping it with an existing OPEN ticket opens that ticket, no new '
        'one created', (tester) async {
      final api = _FakeSupportApi(tickets: [
        const SupportTicket(
          id: 'existing-1',
          reference: 'TKT-1',
          subject: 'Earlier question',
          category: 'OTHER',
          status: 'ANSWERED',
        ),
      ]);
      await tester.pumpWidget(_app(
        auth: const AuthAuthenticated(_token),
        supportApi: api,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-chat-with-support')));
      await tester.pumpAndSettle();

      expect(
          find.text('support-thread-placeholder-existing-1'), findsOneWidget);
      expect(api.lastCreated, isNull);
    });

    testWidgets('tapping it with only a CLOSED ticket starts a new one instead',
        (tester) async {
      final api = _FakeSupportApi(tickets: [
        const SupportTicket(
          id: 'closed-1',
          reference: 'TKT-1',
          subject: 'Old, resolved',
          category: 'OTHER',
          status: 'CLOSED',
        ),
      ]);
      await tester.pumpWidget(_app(
        auth: const AuthAuthenticated(_token),
        supportApi: api,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-chat-with-support')));
      await tester.pumpAndSettle();

      expect(
          find.text('support-thread-placeholder-new-ticket'), findsOneWidget);
      expect(api.lastCreated, isNotNull);
    });

    testWidgets('tapping it with no tickets at all starts a new one',
        (tester) async {
      final api = _FakeSupportApi();
      await tester.pumpWidget(_app(
        auth: const AuthAuthenticated(_token),
        supportApi: api,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-chat-with-support')));
      await tester.pumpAndSettle();

      expect(
          find.text('support-thread-placeholder-new-ticket'), findsOneWidget);
      expect(api.lastCreated?.subject, 'Chat with Support');
    });

    testWidgets('a real server error shows the real message, never crashes',
        (tester) async {
      final api = _FakeSupportApi(
        getTicketsError:
            const ApiException(statusCode: 500, message: 'Server error.'),
      );
      await tester.pumpWidget(_app(
        auth: const AuthAuthenticated(_token),
        supportApi: api,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-chat-with-support')));
      await tester.pumpAndSettle();

      expect(find.text('Server error.'), findsOneWidget);
    });

    testWidgets(
        'a rapid double-tap with no existing tickets creates only one new '
        'ticket, not two', (tester) async {
      final api = _FakeSupportApi(
        getTicketsDelay: const Duration(milliseconds: 50),
      );
      await tester.pumpWidget(_app(
        auth: const AuthAuthenticated(_token),
        supportApi: api,
      ));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('home-chat-with-support'));
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 10));
      // The button must already be disabled while the first tap's
      // getTickets()/createTicket() is still in flight.
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(api.createTicketCalls, 1);
    });
  });
}
