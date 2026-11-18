import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../support/data/models/support_message.dart';

/// Thin seam over [WebSocketChannel] so [SupportSocket] can be tested
/// without a real network connection.
abstract class SupportSocketConnection {
  Stream<dynamic> get stream;
  void add(String data);
  Future<void> close();
  int? get closeCode;
}

class _ChannelConnection implements SupportSocketConnection {
  _ChannelConnection(this._channel);
  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void add(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();

  @override
  int? get closeCode => _channel.closeCode;
}

typedef SupportSocketConnector = SupportSocketConnection Function(Uri uri);

SupportSocketConnection defaultSupportSocketConnector(Uri uri) =>
    _ChannelConnection(WebSocketChannel.connect(uri));

/// Events the live ticket thread (FR-C902) reacts to.
sealed class SupportSocketEvent {}

/// Fired once per new message on the ticket channel, including the
/// sender's own -- dedupe by [SupportMessage.id] against whatever was
/// already optimistically rendered or just-fetched (API.md section 12).
class SupportSocketMessage extends SupportSocketEvent {
  SupportSocketMessage(this.message);
  final SupportMessage message;
}

/// The *other* side's typing signal only; this socket's own
/// [SupportSocket.sendTyping] is never echoed back (API.md section 12).
class SupportSocketTyping extends SupportSocketEvent {
  SupportSocketTyping(this.from);
  final String from;
}

/// Fired on a successful *reconnect* (not the first connect) -- the
/// socket is never the only source of truth, so the screen must
/// re-fetch `GET /support/tickets/{id}` to catch anything sent while
/// disconnected (API.md section 12).
class SupportSocketReconnected extends SupportSocketEvent {}

enum SupportSocketStatus { connecting, connected, disconnected, rejected }

class SupportSocketStatusChanged extends SupportSocketEvent {
  SupportSocketStatusChanged(this.status);
  final SupportSocketStatus status;
}

/// FR-C901: WS client for `wss://.../ws/support/tickets/{id}?token=`
/// (API.md section 12). Auth travels as the `?token=` query param, never
/// a header -- the web client (browser) can't set one on the handshake,
/// and this app matches that contract exactly rather than diverging just
/// because a native client could. Reconnects with exponential backoff
/// capped at 30s; a `4401`/`4403` close is not retried (the same token
/// fails identically every time). This socket only ever *receives* --
/// writing a message stays on the existing REST
/// `POST /support/tickets/{id}/messages` (API.md section 12).
class SupportSocket {
  SupportSocket({
    required this.ticketId,
    required this.apiBaseUrl,
    required this.tokenProvider,
    SupportSocketConnector? connector,
    List<Duration>? backoffSchedule,
  })  : _connector = connector ?? defaultSupportSocketConnector,
        _backoffSchedule = backoffSchedule ??
            const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 4),
              Duration(seconds: 8),
              Duration(seconds: 16),
              Duration(seconds: 30),
            ];

  final String ticketId;
  final String apiBaseUrl;
  final Future<String?> Function() tokenProvider;
  final SupportSocketConnector _connector;
  final List<Duration> _backoffSchedule;

  final _eventsController = StreamController<SupportSocketEvent>.broadcast();
  Stream<SupportSocketEvent> get events => _eventsController.stream;

  SupportSocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _everConnected = false;
  bool _disposed = false;
  bool _permanentlyClosed = false;
  bool _connecting = false;

  /// Guarded against concurrent calls (`_connecting`): the only real
  /// caller is the reconnect timer and the provider's one-shot initial
  /// call, but a second overlapping `connect()` would otherwise stack a
  /// duplicate connection/subscription.
  Future<void> connect() async {
    if (_disposed || _permanentlyClosed || _connecting) return;
    _connecting = true;
    _eventsController
        .add(SupportSocketStatusChanged(SupportSocketStatus.connecting));
    final token = await tokenProvider();
    if (_disposed || token == null) {
      _connecting = false;
      return;
    }

    final SupportSocketConnection connection;
    try {
      connection = _connector(_buildUri(token));
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
      return;
    }
    _connecting = false;
    _connection = connection;
    _subscription = connection.stream.listen(
      _onData,
      onDone: _onClosed,
      onError: (_) => _onClosed(),
      cancelOnError: true,
    );
    _attempt = 0;
    if (_everConnected) {
      _eventsController.add(SupportSocketReconnected());
    }
    _everConnected = true;
    _eventsController
        .add(SupportSocketStatusChanged(SupportSocketStatus.connected));
  }

  Uri _buildUri(String token) {
    final httpUri = Uri.parse(apiBaseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    return httpUri.replace(
      scheme: wsScheme,
      path: '${httpUri.path}/ws/support/tickets/$ticketId',
      queryParameters: {'token': token},
    );
  }

  void _onData(dynamic raw) {
    final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (decoded['type']) {
      case 'message':
        _eventsController.add(SupportSocketMessage(SupportMessage.fromJson(
            decoded['message'] as Map<String, dynamic>)));
      case 'typing':
        _eventsController.add(SupportSocketTyping(decoded['from'] as String));
    }
  }

  void _onClosed() {
    if (_disposed) return;
    final code = _connection?.closeCode;
    if (code == 4401 || code == 4403) {
      _permanentlyClosed = true;
      _eventsController
          .add(SupportSocketStatusChanged(SupportSocketStatus.rejected));
      return;
    }
    _eventsController
        .add(SupportSocketStatusChanged(SupportSocketStatus.disconnected));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _permanentlyClosed) return;
    final delay =
        _backoffSchedule[_attempt.clamp(0, _backoffSchedule.length - 1)];
    _attempt++;
    _reconnectTimer = Timer(delay, connect);
  }

  /// Outbound `{"type":"typing"}` -- ephemeral, never persisted, no ack
  /// (API.md section 12).
  void sendTyping() {
    _connection?.add(jsonEncode({'type': 'typing'}));
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _connection?.close();
    _eventsController.close();
  }
}
