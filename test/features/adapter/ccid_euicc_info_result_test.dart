import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_euicc_info_result.dart';

void main() {
  group('CcidEuiccInfoResult.fromRaw', () {
    test('parses a successful read with the real SGP.22 version and memory',
        () {
      final result = CcidEuiccInfoResult.fromRaw({
        'outcome': 'success',
        'svn': '2.2.0',
        'freeNonVolatileMemory': 427416,
        'freeVolatileMemory': 12544,
      });

      expect(result.outcome, CcidEuiccInfoOutcome.success);
      expect(result.svn, '2.2.0');
      expect(result.freeNonVolatileMemory, 427416);
      expect(result.freeVolatileMemory, 12544);
    });

    test('parses read_failed with no chip info', () {
      final result = CcidEuiccInfoResult.fromRaw({'outcome': 'read_failed'});
      expect(result.outcome, CcidEuiccInfoOutcome.readFailed);
      expect(result.svn, isNull);
    });

    test('parses not_powered_on', () {
      expect(CcidEuiccInfoResult.fromRaw({'outcome': 'not_powered_on'}).outcome,
          CcidEuiccInfoOutcome.notPoweredOn);
    });

    test('parses detached (unplugged mid-read)', () {
      expect(CcidEuiccInfoResult.fromRaw({'outcome': 'detached'}).outcome,
          CcidEuiccInfoOutcome.detached);
    });

    test('an unrecognized outcome maps to unknown, not a crash', () {
      expect(CcidEuiccInfoResult.fromRaw({'outcome': 'something_new'}).outcome,
          CcidEuiccInfoOutcome.unknown);
    });

    test('a missing outcome field maps to unknown, never null-crashes', () {
      expect(CcidEuiccInfoResult.fromRaw(const {}).outcome,
          CcidEuiccInfoOutcome.unknown);
    });
  });
}
