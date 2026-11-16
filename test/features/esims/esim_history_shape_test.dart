import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_history_shape.dart';

void main() {
  group('hasHistorySection', () {
    test('both empty -> false', () {
      expect(hasHistorySection(const [], const []), isFalse);
    });

    test('either non-empty -> true', () {
      expect(hasHistorySection(const [{}], const []), isTrue);
      expect(hasHistorySection(const [], const [{}]), isTrue);
    });
  });

  group('formatHistoryEntry', () {
    test('joins key: value pairs, sorted by key', () {
      expect(
        formatHistoryEntry(const {
          'date': '2026-11-11',
          'used_mb': '120',
        }),
        'date: 2026-11-11, used_mb: 120',
      );
    });

    test('always excludes eid, even if it would otherwise sort first', () {
      final formatted = formatHistoryEntry(const {
        'eid': '89049032...',
        'event': 'ACTIVATED',
      });

      expect(formatted, 'event: ACTIVATED');
      expect(formatted, isNot(contains('89049032')));
    });

    test('an entry with only eid formats to an empty string, never crashes',
        () {
      expect(formatHistoryEntry(const {'eid': 'secret'}), '');
    });
  });
}
