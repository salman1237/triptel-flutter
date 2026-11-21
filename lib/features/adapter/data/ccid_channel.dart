import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('co.triptel.app/ccid');
const _readersChannel = EventChannel('co.triptel.app/ccid/readers');

/// FR-L910: thin wrapper over the native USB CCID reader detector
/// (`UsbCcidReaders.kt`). Returns raw signals; typed parsing happens in
/// `application/ccid_reader.dart` (pure, testable without a platform
/// channel).
abstract class CcidChannel {
  /// Whether this device has USB host mode at all -- checked once, not
  /// part of the hot-plug stream (it can't change at runtime).
  Future<bool> hasUsbHostFeature();

  /// The live list of currently-attached CCID readers, re-emitted on
  /// every attach/detach while the app is foregrounded (native side
  /// registers/unregisters the OS receiver from the activity's own
  /// lifecycle, not a manifest auto-launch).
  Stream<List<Map<String, dynamic>>> watchReaders();
}

class CcidChannelImpl implements CcidChannel {
  @override
  Future<bool> hasUsbHostFeature() async =>
      await _methodChannel.invokeMethod<bool>('hasUsbHostFeature') ?? false;

  @override
  Stream<List<Map<String, dynamic>>> watchReaders() =>
      _readersChannel.receiveBroadcastStream().map(
            (raw) => (raw as List)
                .cast<Map<dynamic, dynamic>>()
                .map((m) => m.cast<String, dynamic>())
                .toList(),
          );
}
