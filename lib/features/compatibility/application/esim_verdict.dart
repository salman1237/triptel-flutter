import '../data/models/esim_raw_signals.dart';
import 'ios_marketing_names.dart';

enum EsimVerdictKind { supported, notSupported, unknown }

/// FR-950's decision logic, kept pure and unit-testable (Architecture.md
/// "Compatibility"): raw signals in, verdict out. "Unknown" is never shown as
/// "not supported" (Rules.md) — it means the app couldn't confirm either way.
class EsimVerdict {
  const EsimVerdict({
    required this.kind,
    required this.deviceLabel,
    required this.reason,
  });

  final EsimVerdictKind kind;
  final String deviceLabel;
  final String reason;
}

EsimVerdict evaluateEsimSupport(EsimRawSignals signals) {
  switch (signals.platform) {
    case 'android':
      return _evaluateAndroid(signals);
    case 'ios':
      return _evaluateIos(signals);
    default:
      return EsimVerdict(
        kind: EsimVerdictKind.unknown,
        deviceLabel: signals.model.isNotEmpty ? signals.model : 'This device',
        reason: 'Unrecognized platform.',
      );
  }
}

EsimVerdict _evaluateAndroid(EsimRawSignals signals) {
  final deviceLabel = [signals.brand, signals.model]
      .where((part) => part.isNotEmpty)
      .join(' ')
      .trim();
  final label = deviceLabel.isEmpty ? 'This device' : deviceLabel;

  final sdkInt = signals.sdkInt;
  if (sdkInt == null || sdkInt < 28) {
    return EsimVerdict(
      kind: EsimVerdictKind.unknown,
      deviceLabel: label,
      reason: 'Android version too old to check eSIM support.',
    );
  }

  final hasFeature = signals.hasEuiccFeature;
  if (hasFeature != true) {
    return EsimVerdict(
      kind: EsimVerdictKind.notSupported,
      deviceLabel: label,
      reason: 'This device has no eSIM hardware.',
    );
  }

  final enabled = signals.euiccEnabled;
  if (enabled == true) {
    return EsimVerdict(
      kind: EsimVerdictKind.supported,
      deviceLabel: label,
      reason: 'eSIM is supported and enabled on this device.',
    );
  }
  return EsimVerdict(
    kind: EsimVerdictKind.unknown,
    deviceLabel: label,
    reason: 'eSIM hardware is present but disabled or locked by the carrier.',
  );
}

EsimVerdict _evaluateIos(EsimRawSignals signals) {
  final label = iosMarketingName(signals.model);

  final embedded = signals.supportsEmbeddedSIM;
  if (embedded != null) {
    return EsimVerdict(
      kind: embedded ? EsimVerdictKind.supported : EsimVerdictKind.notSupported,
      deviceLabel: label,
      reason: embedded
          ? 'eSIM is supported on this device.'
          : 'This device has no eSIM hardware.',
    );
  }

  final legacy = signals.supportsCellularPlan;
  if (legacy != null) {
    return EsimVerdict(
      kind: legacy ? EsimVerdictKind.supported : EsimVerdictKind.notSupported,
      deviceLabel: label,
      reason: legacy
          ? 'eSIM is supported on this device.'
          : 'This device has no eSIM hardware.',
    );
  }

  return EsimVerdict(
    kind: EsimVerdictKind.unknown,
    deviceLabel: label,
    reason: 'iOS version too old to check eSIM support.',
  );
}
