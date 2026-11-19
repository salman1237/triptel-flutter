import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_attachment.dart';
import 'package:triptel/features/support/data/models/support_category.dart';
import 'package:triptel/features/support/data/models/support_message.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';
import 'package:triptel/features/support/presentation/ticket_thread_screen.dart';
import 'package:triptel/features/support_chat/application/support_chat_providers.dart';
import 'package:triptel/features/support_chat/data/support_socket.dart';

const _ticketId = 'ticket-1';

/// Same fake seam as `support_socket_test.dart` -- a hand-driven
/// connection so FR-C902's screen-level tests control exactly what the
/// "live" socket delivers, with no real network and no real
/// `flutter_secure_storage` platform channel involved.
class _FakeConnection implements SupportSocketConnection {
  final _controller = StreamController<dynamic>.broadcast();
  final List<String> sent = [];
  int? _closeCode;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void add(String data) => sent.add(data);

  @override
  Future<void> close() async => _controller.close();

  @override
  int? get closeCode => _closeCode;

  void emit(Map<String, dynamic> json) => _controller.add(jsonEncode(json));

  void simulateServerClose(int? code) {
    _closeCode = code;
    _controller.close();
  }
}

class _FakeSupportApi implements SupportApi {
  _FakeSupportApi(this.ticket);
  SupportTicket ticket;
  int getTicketCalls = 0;

  @override
  Future<SupportTicket> getTicket(String id) async {
    getTicketCalls++;
    return ticket;
  }

  @override
  Future<SupportTicket> replyToTicket(String id,
          {required String body, List<String> filePaths = const []}) =>
      throw UnimplementedError();

  @override
  Future<SupportTicket> closeTicket(String id) => throw UnimplementedError();

  @override
  Future<Uint8List> downloadAttachment(SupportAttachment attachment) =>
      throw UnimplementedError();

  @override
  Future<SupportTicket> createTicket(
          {required String subject,
          required String body,
          required String category,
          List<String> filePaths = const []}) =>
      throw UnimplementedError();

  @override
  Future<List<SupportTicket>> getTickets() => throw UnimplementedError();

  @override
  Future<List<SupportCategory>> getCategories() => throw UnimplementedError();
}

SupportTicket _ticket({List<SupportMessage> messages = const []}) =>
    SupportTicket(
      id: _ticketId,
      reference: 'TKT-TEST-1',
      subject: 'My eSIM is not working',
      category: 'ESIM',
      status: 'ANSWERED',
      messages: messages,
    );

Widget _app(
  _FakeSupportApi api,
  SupportSocketConnector connector, {
  List<Duration>? backoffSchedule,
}) =>
    ProviderScope(
      overrides: [
        supportApiProvider.overrideWithValue(api),
        supportSocketProvider(_ticketId).overrideWith((ref) {
          final socket = SupportSocket(
            ticketId: _ticketId,
            apiBaseUrl: 'https://beta.triptel.co/api/v1',
            tokenProvider: () async => 'test-token',
            connector: connector,
            backoffSchedule: backoffSchedule,
          );
          socket.connect();
          ref.onDispose(socket.dispose);
          return socket;
        }),
      ],
      child: const MaterialApp(home: TicketThreadScreen(ticketId: _ticketId)),
    );

void main() {
  testWidgets(
      'a message delivered live over the socket appears without a '
      'REST refetch', (tester) async {
    final api = _FakeSupportApi(_ticket());
    final connection = _FakeConnection();
    await tester.pumpWidget(_app(api, (_) => connection));
    await tester.pumpAndSettle();
    final callsBeforeLiveMessage = api.getTicketCalls;

    connection.emit({
      'type': 'message',
      'message': {
        'id': 'live-1',
        'body': 'A staff reply, delivered live.',
        'is_staff': true,
        'author': 'Support',
        'author_avatar_url': 'https://beta.triptel.co/avatar.png',
        'created_at': '2026-11-19T10:00:00Z',
        'attachments': [],
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('A staff reply, delivered live.'), findsOneWidget);
    expect(api.getTicketCalls, callsBeforeLiveMessage);
  });

  testWidgets(
      'a live message is not duplicated once the REST thread '
      'catches up with the same id', (tester) async {
    final api = _FakeSupportApi(_ticket());
    final connection = _FakeConnection();
    await tester.pumpWidget(_app(api, (_) => connection));
    await tester.pumpAndSettle();

    connection.emit({
      'type': 'message',
      'message': {
        'id': 'dup-1',
        'body': 'Echoed back over the socket.',
        'is_staff': false,
        'author': 'You',
        'created_at': '2026-11-19T10:00:00Z',
        'attachments': [],
      },
    });
    await tester.pumpAndSettle();
    expect(find.text('Echoed back over the socket.'), findsOneWidget);

    // The REST list now also contains it (e.g. after the sender's own
    // POST .../messages response or a refetch) -- dedupe by id, don't
    // show it twice.
    api.ticket = _ticket(messages: [
      SupportMessage(
        id: 'dup-1',
        body: 'Echoed back over the socket.',
        isStaff: false,
        author: 'You',
        createdAt: DateTime.utc(2026, 11, 19, 10),
        attachments: const [],
      ),
    ]);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(TicketThreadScreen)));
    container.invalidate(supportTicketProvider(_ticketId));
    await tester.pumpAndSettle();

    expect(find.text('Echoed back over the socket.'), findsOneWidget);
  });

  testWidgets(
      'a typing event from staff shows the indicator, which clears '
      'on its own after the documented ~3s', (tester) async {
    final api = _FakeSupportApi(_ticket());
    final connection = _FakeConnection();
    await tester.pumpWidget(_app(api, (_) => connection));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ticket-staff-typing')), findsNothing);

    connection.emit({'type': 'typing', 'from': 'staff'});
    await tester.pump(Duration.zero);
    await tester.pump();

    expect(find.byKey(const ValueKey('ticket-staff-typing')), findsOneWidget);

    // Not `pumpAndSettle` -- `_TypingDots`'s indefinitely-repeating
    // AnimationController never settles while mounted.
    await tester.pump(const Duration(seconds: 4));

    expect(find.byKey(const ValueKey('ticket-staff-typing')), findsNothing);
  });

  testWidgets(
      'a message avatar renders the real author_avatar_url when present',
      (tester) async {
    final api = _FakeSupportApi(_ticket(messages: [
      SupportMessage(
        id: 'm1',
        body: 'Hi, how can I help?',
        isStaff: true,
        author: 'Support',
        authorAvatarUrl: 'https://beta.triptel.co/staff-avatar.png',
        createdAt: DateTime.utc(2026, 11, 19),
        attachments: const [],
      ),
    ]));
    final connection = _FakeConnection();
    await tester.pumpWidget(_app(api, (_) => connection));
    await tester.pump();

    final avatar = tester.widget<KeyedSubtree>(
        find.byKey(const ValueKey('ticket-message-avatar')));
    final image = find.descendant(
      of: find.byWidget(avatar),
      matching: find.byType(CachedNetworkImage),
    );
    expect(image, findsOneWidget);
    expect(tester.widget<CachedNetworkImage>(image).imageUrl,
        'https://beta.triptel.co/staff-avatar.png');
  });

  testWidgets(
      'a reconnect (not the first connect) re-fetches the REST thread, but '
      'typing/message events alone never trigger a spurious refetch',
      (tester) async {
    final api = _FakeSupportApi(_ticket());
    final connections = <_FakeConnection>[];
    await tester.pumpWidget(_app(
      api,
      (_) {
        final c = _FakeConnection();
        connections.add(c);
        return c;
      },
      backoffSchedule: const [Duration(milliseconds: 5)],
    ));
    await tester.pumpAndSettle();
    final callsAfterFirstLoad = api.getTicketCalls;

    // A typing event alone must never trigger a refetch.
    connections.first.emit({'type': 'typing', 'from': 'staff'});
    await tester.pump();
    expect(api.getTicketCalls, callsAfterFirstLoad);

    // An ordinary disconnect (not 4401/4403) reconnects on its own and
    // fires Reconnected -- the screen must re-fetch the REST thread then,
    // since the socket is never the only source of truth (API.md section
    // 12: catches anything sent while disconnected).
    connections.first.simulateServerClose(1000);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(connections, hasLength(2));
    expect(api.getTicketCalls, callsAfterFirstLoad + 1);
  });
}
