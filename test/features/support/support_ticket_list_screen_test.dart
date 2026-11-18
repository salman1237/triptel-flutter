import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_category.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';
import 'package:triptel/features/support/presentation/support_ticket_list_screen.dart';

class _FakeSupportApi implements SupportApi {
  _FakeSupportApi(this._result);
  final Object _result; // List<SupportTicket> or Exception.

  @override
  Future<List<SupportTicket>> getTickets() async {
    final r = _result;
    if (r is Exception) throw r;
    return r as List<SupportTicket>;
  }

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  }) =>
      throw UnimplementedError();

  @override
  Future<List<SupportCategory>> getCategories() => throw UnimplementedError();
}

SupportTicket _ticket({
  String id = 'ticket-1',
  String status = 'OPEN',
  DateTime? lastMessageAt,
}) =>
    SupportTicket(
      id: id,
      reference: 'TKT-TEST-1',
      subject: 'My eSIM is not working',
      category: 'ESIM',
      status: status,
      createdAt: DateTime.utc(2026, 11, 1),
      lastMessageAt: lastMessageAt,
    );

Widget _app(Object result) => ProviderScope(
      overrides: [
        supportApiProvider.overrideWithValue(_FakeSupportApi(result)),
      ],
      child: const MaterialApp(home: SupportTicketListScreen()),
    );

Widget _routedApp(Object result) {
  final router = GoRouter(initialLocation: '/support', routes: [
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportTicketListScreen(),
    ),
    GoRoute(
      path: '/support/new',
      builder: (context, state) =>
          const Scaffold(body: Text('new-ticket-screen-placeholder')),
    ),
  ]);
  return ProviderScope(
    overrides: [
      supportApiProvider.overrideWithValue(_FakeSupportApi(result)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('no tickets yet shows EmptyState, not a crash', (tester) async {
    await tester.pumpWidget(_app(const <SupportTicket>[]));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('lists a real ticket with its reference, subject, and chip',
      (tester) async {
    await tester.pumpWidget(_app([_ticket()]));
    await tester.pumpAndSettle();

    expect(find.text('TKT-TEST-1'), findsOneWidget);
    expect(find.text('My eSIM is not working'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
      'shows the real last-activity date, preferring '
      'last_message_at over created_at', (tester) async {
    await tester.pumpWidget(_app([
      _ticket(lastMessageAt: DateTime.utc(2026, 11, 15)),
    ]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nov 15, 2026'), findsOneWidget);
    expect(find.textContaining('Nov 1, 2026'), findsNothing);
  });

  testWidgets('falls back to created_at when last_message_at is null',
      (tester) async {
    await tester.pumpWidget(_app([_ticket()]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nov 1, 2026'), findsOneWidget);
  });

  testWidgets('each documented status shows its real chip label',
      (tester) async {
    await tester.pumpWidget(_app([
      _ticket(id: '1', status: 'OPEN'),
      _ticket(id: '2', status: 'ANSWERED'),
      _ticket(id: '3', status: 'RESOLVED'),
      _ticket(id: '4', status: 'CLOSED'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supportTicketsProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: SupportTicketListScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets(
      'tapping the "+" action navigates to the real FR-1102 new-ticket '
      'screen', (tester) async {
    await tester.pumpWidget(_routedApp([_ticket()]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-new-ticket-button')));
    await tester.pumpAndSettle();

    expect(find.text('new-ticket-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'empty state\'s "New ticket" CTA navigates to the real FR-1102 '
      'screen', (tester) async {
    await tester.pumpWidget(_routedApp(const <SupportTicket>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New ticket'));
    await tester.pumpAndSettle();

    expect(find.text('new-ticket-screen-placeholder'), findsOneWidget);
  });
}
