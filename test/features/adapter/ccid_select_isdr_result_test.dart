import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_select_isdr_result.dart';

void main() {
  group('CcidSelectIsdRResult.fromRaw', () {
    test('parses a successful SELECT with its real FCI and status word', () {
      final result = CcidSelectIsdRResult.fromRaw({
        'outcome': 'success',
        'channel': 1,
        'sw': '9000',
        'success': true,
        'fciHex': '6F108408A000000559101001A5049F6501FF',
      });

      expect(result.outcome, CcidSelectIsdROutcome.success);
      expect(result.channel, 1);
      expect(result.sw, '9000');
      expect(result.swIsSuccess, isTrue);
      expect(result.fciHex, '6F108408A000000559101001A5049F6501FF');
    });

    test('parses a success outcome whose final status word was not 9000', () {
      final result = CcidSelectIsdRResult.fromRaw({
        'outcome': 'success',
        'channel': 1,
        'sw': '6a82',
        'success': false,
        'fciHex': '',
      });

      expect(result.outcome, CcidSelectIsdROutcome.success);
      expect(result.swIsSuccess, isFalse);
    });

    test('parses channel_open_failed with the native reason', () {
      final result = CcidSelectIsdRResult.fromRaw({
        'outcome': 'channel_open_failed',
        'reason': 'SW=6e00',
      });

      expect(result.outcome, CcidSelectIsdROutcome.channelOpenFailed);
      expect(result.reason, 'SW=6e00');
    });

    test('parses select_failed with its channel and reason', () {
      final result = CcidSelectIsdRResult.fromRaw({
        'outcome': 'select_failed',
        'channel': 1,
        'reason': 'no_response',
      });

      expect(result.outcome, CcidSelectIsdROutcome.selectFailed);
      expect(result.channel, 1);
    });

    test('parses not_powered_on', () {
      expect(
          CcidSelectIsdRResult.fromRaw({'outcome': 'not_powered_on'}).outcome,
          CcidSelectIsdROutcome.notPoweredOn);
    });

    test('an unrecognized outcome maps to unknown, not a crash', () {
      expect(CcidSelectIsdRResult.fromRaw({'outcome': 'something_new'}).outcome,
          CcidSelectIsdROutcome.unknown);
    });

    test('a missing outcome field maps to unknown, never null-crashes', () {
      expect(CcidSelectIsdRResult.fromRaw(const {}).outcome,
          CcidSelectIsdROutcome.unknown);
    });
  });
}
