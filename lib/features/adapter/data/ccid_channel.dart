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

  /// FR-L911: requests the standard per-device USB permission for the
  /// reader with this `deviceId`. Always resolves (never throws) to a
  /// raw `{"result": "granted"|"denied"|"detached_meanwhile"|...}` map.
  Future<Map<String, dynamic>> requestPermission(int deviceId);

  /// FR-L912: powers on the card in this reader (with voltage
  /// fallback) and returns the real ATR, or a typed failure. Always
  /// resolves (never throws) to a raw
  /// `{"outcome": "success"|"power_on_failed"|"no_permission"|...}` map.
  Future<Map<String, dynamic>> powerOn(int deviceId);

  /// FR-L913: opens a logical channel and selects ISD-R by AID on it
  /// (following T=0's response-chaining rules), then closes the
  /// channel again. Requires the card to already be powered on.
  /// Always resolves (never throws) to a raw
  /// `{"outcome": "success"|"select_failed"|"not_powered_on"|...}` map.
  Future<Map<String, dynamic>> selectIsdR(int deviceId);
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

  @override
  Future<Map<String, dynamic>> requestPermission(int deviceId) async {
    final raw = await _methodChannel.invokeMapMethod<String, dynamic>(
        'requestPermission', {'deviceId': deviceId});
    return raw ?? const {};
  }

  @override
  Future<Map<String, dynamic>> powerOn(int deviceId) async {
    final raw = await _methodChannel
        .invokeMapMethod<String, dynamic>('powerOn', {'deviceId': deviceId});
    return raw ?? const {};
  }

  @override
  Future<Map<String, dynamic>> selectIsdR(int deviceId) async {
    final raw = await _methodChannel
        .invokeMapMethod<String, dynamic>('selectIsdR', {'deviceId': deviceId});
    return raw ?? const {};
  }
}
