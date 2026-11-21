/// FR-L912: the real, observed outcome of powering on the card in a
/// CCID reader -- never a prediction. `success` carries the real ATR
/// bytes (hex) and the protocol(s) the card actually offered.
enum CcidPowerOnOutcome {
  success,
  powerOnFailed,
  noPermission,
  detached,
  openFailed,

  /// The native side returned an `outcome` string this Dart code
  /// doesn't recognize yet -- surfaced honestly rather than silently
  /// mapped to some other outcome.
  unknown,
}

class CcidPowerOnResult {
  const CcidPowerOnResult({
    required this.outcome,
    this.atrHex,
    this.protocols = const [],
    this.preferredProtocol,
    this.checksumValid,
    this.voltage,
    this.reason,
    this.error,
  });

  final CcidPowerOnOutcome outcome;

  /// Hex-encoded raw ATR bytes. Only present when [outcome] is
  /// [CcidPowerOnOutcome.success].
  final String? atrHex;

  /// The protocol(s) the card offered, e.g. `[0]` for T=0 only, `[0, 1]`
  /// if it also offers T=1.
  final List<int> protocols;

  /// The protocol this adapter would actually use (prefers T=1).
  final int? preferredProtocol;
  final bool? checksumValid;

  /// The voltage that produced a valid ATR (`V5_0`/`V3_0`/`V1_8`), after
  /// the native side's fallback sequence.
  final String? voltage;

  /// A plain-language reason, only present when [outcome] is
  /// [CcidPowerOnOutcome.powerOnFailed].
  final String? reason;
  final int? error;

  factory CcidPowerOnResult.fromRaw(Map<String, dynamic> raw) =>
      CcidPowerOnResult(
        outcome: _parseOutcome(raw['outcome'] as String?),
        atrHex: raw['atrHex'] as String?,
        protocols: (raw['protocols'] as List?)?.cast<int>() ?? const [],
        preferredProtocol: raw['preferredProtocol'] as int?,
        checksumValid: raw['checksumValid'] as bool?,
        voltage: raw['voltage'] as String?,
        reason: raw['reason'] as String?,
        error: raw['error'] as int?,
      );
}

CcidPowerOnOutcome _parseOutcome(String? raw) => switch (raw) {
      'success' => CcidPowerOnOutcome.success,
      'power_on_failed' => CcidPowerOnOutcome.powerOnFailed,
      'no_permission' => CcidPowerOnOutcome.noPermission,
      'detached' => CcidPowerOnOutcome.detached,
      'open_failed' => CcidPowerOnOutcome.openFailed,
      _ => CcidPowerOnOutcome.unknown,
    };
