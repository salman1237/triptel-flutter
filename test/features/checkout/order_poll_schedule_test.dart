import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/application/order_poll_schedule.dart';

void main() {
  test('first phase polls every 2s for ~12s (6 polls)', () {
    final schedule = orderPollSchedule();
    expect(schedule.take(6), everyElement(const Duration(seconds: 2)));
  });

  test('second phase polls every 5s after the first phase', () {
    final schedule = orderPollSchedule();
    expect(schedule.skip(6), everyElement(const Duration(seconds: 5)));
  });

  test('total elapsed time is at least ~170s and the schedule is non-empty',
      () {
    final schedule = orderPollSchedule();
    expect(schedule, isNotEmpty);
    final total = schedule.fold(Duration.zero, (sum, d) => sum + d);
    expect(total.inSeconds, greaterThanOrEqualTo(170));
    expect(total.inSeconds, lessThan(180));
  });
}
