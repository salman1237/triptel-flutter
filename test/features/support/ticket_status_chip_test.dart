import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/widgets/status_chip.dart';
import 'package:triptel/features/support/application/ticket_status_chip.dart';

void main() {
  test('every documented ticket status (API.md section 12) has a chip', () {
    expect(ticketStatusChip('OPEN'), (label: 'Open', tone: StatusTone.info));
    expect(ticketStatusChip('ANSWERED'),
        (label: 'Answered', tone: StatusTone.warning));
    expect(ticketStatusChip('RESOLVED'),
        (label: 'Resolved', tone: StatusTone.success));
    expect(
        ticketStatusChip('CLOSED'), (label: 'Closed', tone: StatusTone.danger));
  });

  test('an undocumented future status falls back to the raw value, warning',
      () {
    expect(ticketStatusChip('SOME_NEW_STATUS'),
        (label: 'SOME_NEW_STATUS', tone: StatusTone.warning));
  });
}
