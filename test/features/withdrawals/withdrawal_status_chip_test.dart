import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/widgets/status_chip.dart';
import 'package:triptel/features/withdrawals/application/withdrawal_status_chip.dart';

void main() {
  test('every documented withdrawal status (API.md section 10) has a chip', () {
    expect(withdrawalStatusChip('PENDING'),
        (label: 'Pending', tone: StatusTone.warning));
    expect(withdrawalStatusChip('PAID'),
        (label: 'Paid', tone: StatusTone.success));
    expect(withdrawalStatusChip('REJECTED'),
        (label: 'Rejected', tone: StatusTone.danger));
  });

  test(
      'CANCELLED is info (sky), not danger -- it is user-initiated and '
      'non-punitive (the backend returns the held balance)', () {
    expect(withdrawalStatusChip('CANCELLED'),
        (label: 'Cancelled', tone: StatusTone.info));
  });

  test('an undocumented future status falls back to the raw value, warning',
      () {
    expect(withdrawalStatusChip('SOME_NEW_STATUS'),
        (label: 'SOME_NEW_STATUS', tone: StatusTone.warning));
  });
}
