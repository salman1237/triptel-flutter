import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_power_on_result.dart';

void main() {
  group('CcidPowerOnResult.fromRaw', () {
    test('parses a successful power-on with the real ATR shape', () {
      final result = CcidPowerOnResult.fromRaw({
        'outcome': 'success',
        'atrHex': '3B9F96801FC78031E073FE211B64D0009000FA',
        'protocols': [0, 1],
        'preferredProtocol': 1,
        'checksumValid': true,
        'voltage': 'V5_0',
      });

      expect(result.outcome, CcidPowerOnOutcome.success);
      expect(result.atrHex, '3B9F96801FC78031E073FE211B64D0009000FA');
      expect(result.protocols, [0, 1]);
      expect(result.preferredProtocol, 1);
      expect(result.checksumValid, isTrue);
      expect(result.voltage, 'V5_0');
    });

    test('parses a power_on_failed result with the native reason', () {
      final result = CcidPowerOnResult.fromRaw({
        'outcome': 'power_on_failed',
        'reason': 'ICC_MUTE: no response from the card (not inserted, or '
            'dead)',
        'error': 0xFE,
      });

      expect(result.outcome, CcidPowerOnOutcome.powerOnFailed);
      expect(result.reason, contains('ICC_MUTE'));
      expect(result.error, 0xFE);
    });

    test('parses no_permission', () {
      expect(CcidPowerOnResult.fromRaw({'outcome': 'no_permission'}).outcome,
          CcidPowerOnOutcome.noPermission);
    });

    test('parses detached', () {
      expect(CcidPowerOnResult.fromRaw({'outcome': 'detached'}).outcome,
          CcidPowerOnOutcome.detached);
    });

    test('parses open_failed', () {
      expect(CcidPowerOnResult.fromRaw({'outcome': 'open_failed'}).outcome,
          CcidPowerOnOutcome.openFailed);
    });

    test('an unrecognized outcome maps to unknown, not a crash', () {
      expect(CcidPowerOnResult.fromRaw({'outcome': 'something_new'}).outcome,
          CcidPowerOnOutcome.unknown);
    });

    test('a missing outcome field maps to unknown, never null-crashes', () {
      expect(CcidPowerOnResult.fromRaw(const {}).outcome,
          CcidPowerOnOutcome.unknown);
    });

    test('a failure result carries no protocols/ATR data', () {
      final result = CcidPowerOnResult.fromRaw({'outcome': 'power_on_failed'});
      expect(result.atrHex, isNull);
      expect(result.protocols, isEmpty);
    });
  });
}
