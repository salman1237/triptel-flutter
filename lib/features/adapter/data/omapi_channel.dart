import 'package:flutter/services.dart';

const _channel = MethodChannel('co.triptel.app/omapi');

/// FR-L905: thin wrapper over the native OMAPI probe (`OmapiProbe.kt`).
/// Returns the raw signal map; typed parsing happens in
/// `application/omapi_probe_result.dart` (pure, testable without a
/// platform channel).
abstract class OmapiChannel {
  Future<Map<String, dynamic>> probeUiccSecureElement();
}

class OmapiChannelImpl implements OmapiChannel {
  @override
  Future<Map<String, dynamic>> probeUiccSecureElement() async {
    final raw = await _channel
        .invokeMapMethod<String, dynamic>('probeUiccSecureElement');
    return raw ?? const {};
  }
}
