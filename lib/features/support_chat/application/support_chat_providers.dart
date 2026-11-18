import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/storage/secure_store_provider.dart';
import '../data/support_socket.dart';

/// FR-C901: one live [SupportSocket] per open ticket thread -- the
/// `useSupportSocket` equivalent of web's chat widget. Connects as soon
/// as the thread screen (FR-C902) starts watching it, and disposes (and
/// stops reconnecting) as soon as nothing watches it anymore.
final supportSocketProvider =
    Provider.autoDispose.family<SupportSocket, String>((ref, ticketId) {
  final secureStore = ref.watch(secureStoreProvider);
  final socket = SupportSocket(
    ticketId: ticketId,
    apiBaseUrl: Env.apiBaseUrl,
    tokenProvider: secureStore.readToken,
  );
  socket.connect();
  ref.onDispose(socket.dispose);
  return socket;
});
