import '../../../core/widgets/status_chip.dart';

/// FR-703's status chip mapping. `CANCELLED` is `info` (sky), not `danger`
/// -- unlike an eSIM order's CANCELLED (a failure outcome), a cancelled
/// withdrawal is user-initiated and non-punitive (the held balance is
/// returned, confirmed in the backend's own `cancel_withdrawal` ->
/// `_return_held_balance`), so it doesn't read as a negative result.
({String label, StatusTone tone}) withdrawalStatusChip(String status) =>
    switch (status) {
      'PENDING' => (label: 'Pending', tone: StatusTone.warning),
      'PAID' => (label: 'Paid', tone: StatusTone.success),
      'REJECTED' => (label: 'Rejected', tone: StatusTone.danger),
      'CANCELLED' => (label: 'Cancelled', tone: StatusTone.info),
      _ => (label: status, tone: StatusTone.warning),
    };
