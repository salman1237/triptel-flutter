import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/support_ticket.dart';
import '../data/support_api.dart';

final supportApiProvider = Provider<SupportApi>(
  (ref) => SupportApiImpl(ref.watch(apiClientProvider)),
);

/// FR-1101: the signed-in user's support tickets, newest activity first.
final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportApiProvider).getTickets();
});
