import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/support_category.dart';
import '../data/models/support_ticket.dart';
import '../data/support_api.dart';

final supportApiProvider = Provider<SupportApi>(
  (ref) => SupportApiImpl(ref.watch(apiClientProvider)),
);

/// FR-1101: the signed-in user's support tickets, newest activity first.
final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportApiProvider).getTickets();
});

/// FR-1102: the real category list (PARTNER already filtered out by
/// `SupportApi.getCategories` -- hidden in this customer app).
final supportCategoriesProvider = FutureProvider<List<SupportCategory>>((ref) {
  return ref.watch(supportApiProvider).getCategories();
});

/// FR-1103: a single ticket's full thread (`GET /support/tickets/{id}`).
final supportTicketProvider =
    FutureProvider.family<SupportTicket, String>((ref, id) {
  return ref.watch(supportApiProvider).getTicket(id);
});
