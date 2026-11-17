import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/support_providers.dart';
import '../application/ticket_status_chip.dart';
import '../data/models/support_ticket.dart';

/// FR-1101: support ticket list. `GET /support/tickets`, newest activity
/// first (already sorted server-side) -- reference, subject, status chip,
/// last activity. Rows aren't tappable yet (FR-1103's thread screen isn't
/// built).
class SupportTicketListScreen extends ConsumerWidget {
  const SupportTicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return TriptelScaffold(
      key: const ValueKey('support-ticket-list-screen'),
      appBar: AppBar(title: const Text('Support')),
      scrollable: false,
      body: switch (ticketsAsync) {
        AsyncData(:final value) => value.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.support_agent_outlined,
                  message: "You haven't contacted support yet.",
                ),
              )
            : ListView.separated(
                itemCount: value.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.line),
                itemBuilder: (context, i) => _TicketRow(ticket: value[i]),
              ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your support tickets.",
              onRetry: () => ref.invalidate(supportTicketsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final chip = ticketStatusChip(ticket.status);
    final lastActivity = ticket.lastMessageAt ?? ticket.createdAt;
    return Padding(
      key: ValueKey('support-ticket-row-${ticket.id}'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ticket.reference,
              style: AppTypography.caption(color: AppColors.inkMuted)),
          const SizedBox(height: 2),
          Text(ticket.subject, style: AppTypography.body()),
          const SizedBox(height: 4),
          Row(
            children: [
              StatusChip(label: chip.label, tone: chip.tone),
              if (lastActivity != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(lastActivity.toLocal()),
                  style: AppTypography.caption(color: AppColors.inkMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
