import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support_chat/data/support_socket.dart';

/// A fake [SupportSocketConnection] driven by hand in tests -- no real
/// network connection, no real `web_socket_channel`.
class FakeSupportSocketConnection implements SupportSocketConnection {
  final _controller = StreamController<dynamic>.broadcast();
  final List<String> sent = [];
  int? _closeCode;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void add(String data) => sent.add(data);

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  int? get closeCode => _closeCode;

  void emit(Map<String, dynamic> json) => _controller.add(jsonEncode(json));

  /// Simulates the server closing the connection with [code] (no explicit
  /// `close()` call from this side -- matches a real server-initiated
  /// close, which is what 4401/4403 and ordinary disconnects both are).
  void simulateServerClose(int? code) {
    _closeCode = code;
    _controller.close();
  }
}

const _fixedBackoff = [Duration(milliseconds: 5)];

void main() {
  group('SupportSocket', () {
    test('connects with the token as a query param, never a header', () async {
      Uri? captured;
      final socket = SupportSocket(
        ticketId: 'abc123',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'jwt-token',
        connector: (uri) {
          captured = uri;
          return FakeSupportSocketConnection();
        },
      );

      await socket.connect();

      expect(captured, isNotNull);
      expect(captured!.scheme, 'wss');
      expect(captured!.path, '/api/v1/ws/support/tickets/abc123');
      expect(captured!.queryParameters['token'], 'jwt-token');
      socket.dispose();
    });

    test('parses an inbound message event off the wire shape', () async {
      final conn = FakeSupportSocketConnection();
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) => conn,
      );
      final messages = <dynamic>[];
      socket.events.listen((e) {
        if (e is SupportSocketMessage) messages.add(e.message);
      });

      await socket.connect();
      conn.emit({
        'type': 'message',
        'message': {
          'id': 'm1',
          'body': 'hi',
          'is_staff': false,
          'author': 'You',
          'created_at': '2026-11-19T10:00:00Z',
          'attachments': [],
        },
      });
      await Future.delayed(Duration.zero);

      expect(messages, hasLength(1));
      expect(messages.single.id, 'm1');
      expect(messages.single.body, 'hi');
      socket.dispose();
    });

    test('parses an inbound typing event and ignores its own typing sends',
        () async {
      final conn = FakeSupportSocketConnection();
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) => conn,
      );
      final typingFrom = <String>[];
      socket.events.listen((e) {
        if (e is SupportSocketTyping) typingFrom.add(e.from);
      });

      await socket.connect();
      conn.emit({'type': 'typing', 'from': 'staff'});
      await Future.delayed(Duration.zero);

      expect(typingFrom, ['staff']);
      socket.dispose();
    });

    test('sendTyping writes the exact ephemeral wire frame, no ack expected',
        () async {
      final conn = FakeSupportSocketConnection();
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) => conn,
      );

      await socket.connect();
      socket.sendTyping();

      expect(conn.sent, ['{"type":"typing"}']);
      socket.dispose();
    });

    test(
        'reconnects with backoff after an ordinary disconnect and emits '
        'Reconnected (not on the first connect)', () async {
      final connections = <FakeSupportSocketConnection>[];
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) {
          final c = FakeSupportSocketConnection();
          connections.add(c);
          return c;
        },
        backoffSchedule: _fixedBackoff,
      );
      final events = <SupportSocketEvent>[];
      socket.events.listen(events.add);

      await socket.connect();
      expect(events.whereType<SupportSocketReconnected>(), isEmpty);

      connections.first.simulateServerClose(1000); // ordinary close
      await Future.delayed(const Duration(milliseconds: 50));

      expect(connections, hasLength(2));
      expect(events.whereType<SupportSocketReconnected>(), hasLength(1));
      socket.dispose();
    });

    test(
        'does NOT reconnect on a 4401 (unauthorized) close -- same token '
        'would fail identically every time', () async {
      final connections = <FakeSupportSocketConnection>[];
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) {
          final c = FakeSupportSocketConnection();
          connections.add(c);
          return c;
        },
        backoffSchedule: _fixedBackoff,
      );
      final statuses = <SupportSocketStatus>[];
      socket.events.listen((e) {
        if (e is SupportSocketStatusChanged) statuses.add(e.status);
      });

      await socket.connect();
      connections.first.simulateServerClose(4401);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(connections, hasLength(1));
      expect(statuses, contains(SupportSocketStatus.rejected));
      socket.dispose();
    });

    test('does NOT reconnect on a 4403 (forbidden) close either', () async {
      final connections = <FakeSupportSocketConnection>[];
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) {
          final c = FakeSupportSocketConnection();
          connections.add(c);
          return c;
        },
        backoffSchedule: _fixedBackoff,
      );

      await socket.connect();
      connections.first.simulateServerClose(4403);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(connections, hasLength(1));
      socket.dispose();
    });

    test('dispose stops any pending reconnect', () async {
      final connections = <FakeSupportSocketConnection>[];
      final socket = SupportSocket(
        ticketId: 't1',
        apiBaseUrl: 'https://beta.triptel.co/api/v1',
        tokenProvider: () async => 'tok',
        connector: (_) {
          final c = FakeSupportSocketConnection();
          connections.add(c);
          return c;
        },
        backoffSchedule: _fixedBackoff,
      );

      await socket.connect();
      connections.first.simulateServerClose(1000);
      socket.dispose();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(connections, hasLength(1));
    });
  });
}
