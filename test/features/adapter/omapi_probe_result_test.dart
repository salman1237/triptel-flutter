import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/omapi_probe_result.dart';

void main() {
  group('OmapiProbeResult.fromRaw', () {
    test(
        'parses a granted channel_opened result, including the SELECT '
        'response hex evidence', () {
      final result = OmapiProbeResult.fromRaw({
        'available': true,
        'reason': 'channel_opened',
        'readerNames': ['SIM1'],
        'selectResponseHex': '9000',
      });

      expect(result.available, isTrue);
      expect(result.reason, OmapiProbeReason.channelOpened);
      expect(result.readerNames, ['SIM1']);
      expect(result.selectResponseHex, '9000');
      expect(result.summary(), contains('Channel opened'));
    });

    test('parses an ara_m_denied result with the real error message', () {
      final result = OmapiProbeResult.fromRaw({
        'available': false,
        'reason': 'ara_m_denied',
        'readerNames': ['SIM1'],
        'error': 'No access rule found',
      });

      expect(result.available, isFalse);
      expect(result.reason, OmapiProbeReason.araMDenied);
      expect(result.error, 'No access rule found');
      expect(result.summary(), contains('Denied'));
    });

    for (final entry in {
      'no_uicc_reader': OmapiProbeReason.noUiccReader,
      'no_se_present': OmapiProbeReason.noSePresent,
      'open_session_failed': OmapiProbeReason.openSessionFailed,
      'open_channel_failed': OmapiProbeReason.openChannelFailed,
      'se_service_init_failed': OmapiProbeReason.seServiceInitFailed,
      'service_connect_timeout': OmapiProbeReason.serviceConnectTimeout,
      'omapi_requires_api28': OmapiProbeReason.omapiRequiresApi28,
      'exception': OmapiProbeReason.exception,
    }.entries) {
      test('maps the documented native reason "${entry.key}"', () {
        final result = OmapiProbeResult.fromRaw({
          'available': false,
          'reason': entry.key,
        });

        expect(result.reason, entry.value);
        expect(result.summary(), isNotEmpty);
      });
    }

    test('an unrecognized reason string maps to unknown, not a crash', () {
      final result = OmapiProbeResult.fromRaw({
        'available': false,
        'reason': 'some_future_native_reason',
      });

      expect(result.reason, OmapiProbeReason.unknown);
      expect(result.summary(), isNotEmpty);
    });

    test(
        'defaults available to false and readerNames to empty when '
        'absent (a malformed/empty native response is never '
        'misread as a grant)', () {
      final result = OmapiProbeResult.fromRaw(const {});

      expect(result.available, isFalse);
      expect(result.readerNames, isEmpty);
      expect(result.error, isNull);
      expect(result.selectResponseHex, isNull);
    });
  });
}
