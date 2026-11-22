import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_read_eid_result.dart';

void main() {
  group('CcidReadEidResult.fromRaw', () {
    test('parses a successful read with the real EID', () {
      final result = CcidReadEidResult.fromRaw({
        'outcome': 'success',
        'eid': '89086030000000000135090432000000',
      });

      expect(result.outcome, CcidReadEidOutcome.success);
      expect(result.eid, '89086030000000000135090432000000');
    });

    test('parses read_failed with no EID', () {
      final result = CcidReadEidResult.fromRaw({'outcome': 'read_failed'});
      expect(result.outcome, CcidReadEidOutcome.readFailed);
      expect(result.eid, isNull);
    });

    test('parses not_powered_on', () {
      expect(CcidReadEidResult.fromRaw({'outcome': 'not_powered_on'}).outcome,
          CcidReadEidOutcome.notPoweredOn);
    });

    test('an unrecognized outcome maps to unknown, not a crash', () {
      expect(CcidReadEidResult.fromRaw({'outcome': 'something_new'}).outcome,
          CcidReadEidOutcome.unknown);
    });

    test('a missing outcome field maps to unknown, never null-crashes', () {
      expect(CcidReadEidResult.fromRaw(const {}).outcome,
          CcidReadEidOutcome.unknown);
    });
  });
}
