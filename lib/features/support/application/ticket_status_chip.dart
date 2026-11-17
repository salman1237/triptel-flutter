import '../../../core/widgets/status_chip.dart';

/// FR-1101's status chip mapping -- the backend's `TicketStatus`
/// (OPEN/ANSWERED/RESOLVED/CLOSED) isn't covered by Design_System.md's
/// eSIM-lifecycle convention, so this is its own judgment call (see
/// DECISIONS.md): ANSWERED means "support replied, it's your turn" --
/// the one state that actually needs the customer's attention, so it
/// gets `warning`. CLOSED is `danger` (terminal, same family as
/// Design_System.md's Cancelled/Expired -- distinct from OPEN's `info`,
/// since conflating "just filed" with "done" would make the two
/// opposite ends of the lifecycle visually identical).
({String label, StatusTone tone}) ticketStatusChip(String status) =>
    switch (status) {
      'OPEN' => (label: 'Open', tone: StatusTone.info),
      'ANSWERED' => (label: 'Answered', tone: StatusTone.warning),
      'RESOLVED' => (label: 'Resolved', tone: StatusTone.success),
      'CLOSED' => (label: 'Closed', tone: StatusTone.danger),
      _ => (label: status, tone: StatusTone.warning),
    };
