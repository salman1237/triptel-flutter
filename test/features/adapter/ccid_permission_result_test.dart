import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_permission_result.dart';

void main() {
  group('parseCcidPermissionResult', () {
    test('parses granted', () {
      expect(parseCcidPermissionResult({'result': 'granted'}),
          CcidPermissionResult.granted);
    });

    test('parses denied', () {
      expect(parseCcidPermissionResult({'result': 'denied'}),
          CcidPermissionResult.denied);
    });

    test('parses detached_meanwhile', () {
      expect(parseCcidPermissionResult({'result': 'detached_meanwhile'}),
          CcidPermissionResult.detachedMeanwhile);
    });

    test('parses exception', () {
      expect(parseCcidPermissionResult({'result': 'exception'}),
          CcidPermissionResult.exception);
    });

    test('an unrecognized result maps to unknown, not a crash', () {
      expect(parseCcidPermissionResult({'result': 'something_new'}),
          CcidPermissionResult.unknown);
    });

    test('a missing result field maps to unknown', () {
      expect(parseCcidPermissionResult(const {}), CcidPermissionResult.unknown);
    });
  });
}
