import 'package:flutter/services.dart';
import 'models/esim_raw_signals.dart';

/// Wraps the native `co.triptel.app/esim` channel (MainActivity.kt /
/// AppDelegate.swift) — raw signals only. NFR: device identifiers never
/// leave the device, so nothing here is sent to the API.
abstract class EsimSupportChannel {
  Future<EsimRawSignals> getSignals();
}

class EsimSupportChannelImpl implements EsimSupportChannel {
  static const _channel = MethodChannel('co.triptel.app/esim');

  @override
  Future<EsimRawSignals> getSignals() async {
    final result = await _channel.invokeMethod('getEsimSupport');
    return EsimRawSignals.fromMap(Map<Object?, Object?>.from(result as Map));
  }
}
