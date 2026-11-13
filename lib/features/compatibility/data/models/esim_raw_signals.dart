/// Raw, undecided signals from the native `co.triptel.app/esim` channel
/// (MainActivity.kt / AppDelegate.swift). The verdict is decided in pure Dart
/// (`evaluateEsimSupport`), not here, so the decision logic stays unit-testable
/// without a platform channel.
class EsimRawSignals {
  const EsimRawSignals({
    required this.platform,
    required this.osVersion,
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    this.sdkInt,
    this.hasEuiccFeature,
    this.euiccEnabled,
    this.supportsCellularPlan,
    this.supportsEmbeddedSIM,
  });

  final String platform;
  final String osVersion;
  final String manufacturer;
  final String brand;
  final String model;
  final String device;

  // Android-only.
  final int? sdkInt;
  final bool? hasEuiccFeature;
  final bool? euiccEnabled;

  // iOS-only.
  final bool? supportsCellularPlan;
  final bool? supportsEmbeddedSIM;

  factory EsimRawSignals.fromMap(Map<Object?, Object?> map) => EsimRawSignals(
        platform: map['platform'] as String? ?? 'unknown',
        osVersion: map['osVersion'] as String? ?? '',
        manufacturer: map['manufacturer'] as String? ?? '',
        brand: map['brand'] as String? ?? '',
        model: map['model'] as String? ?? '',
        device: map['device'] as String? ?? '',
        sdkInt: map['sdkInt'] as int?,
        hasEuiccFeature: map['hasEuiccFeature'] as bool?,
        euiccEnabled: map['euiccEnabled'] as bool?,
        supportsCellularPlan: map['supportsCellularPlan'] as bool?,
        supportsEmbeddedSIM: map['supportsEmbeddedSIM'] as bool?,
      );
}
