import '../../../core/widgets/status_chip.dart';

/// FR-703's status chip mapping, following Design_System.md's documented
/// convention (Cancelled/Rejected/Failed -> `danger`).
({String label, StatusTone tone}) withdrawalStatusChip(String status) =>
    switch (status) {
      'PENDING' => (label: 'Pending', tone: StatusTone.warning),
      'PAID' => (label: 'Paid', tone: StatusTone.success),
      'REJECTED' => (label: 'Rejected', tone: StatusTone.danger),
      'CANCELLED' => (label: 'Cancelled', tone: StatusTone.danger),
      _ => (label: status, tone: StatusTone.warning),
    };
