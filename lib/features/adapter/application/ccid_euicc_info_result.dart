/// FR-L915: the real, observed outcome of reading the card's EuiccInfo2
/// summary (SGP.22 spec version, free memory) via lpac's `euicc/` --
/// never a prediction. Card info stays on-device (`docs/Rules.md`).
enum CcidEuiccInfoOutcome {
  success,
  readFailed,
  notPoweredOn,

  /// The reader was unplugged mid-read -- distinct from a generic
  /// [readFailed] (re-checked natively against the live USB device
  /// list at the moment of failure, not guessed).
  detached,

  /// The native side returned an `outcome` string this Dart code
  /// doesn't recognize yet -- surfaced honestly rather than silently
  /// mapped to some other outcome.
  unknown,
}

class CcidEuiccInfoResult {
  const CcidEuiccInfoResult({
    required this.outcome,
    this.svn,
    this.freeNonVolatileMemory,
    this.freeVolatileMemory,
  });

  final CcidEuiccInfoOutcome outcome;

  /// SGP.22 spec version number (e.g. "2.2.0"), only present on
  /// [CcidEuiccInfoOutcome.success].
  final String? svn;

  /// Free non-volatile memory on the card, in bytes.
  final int? freeNonVolatileMemory;

  /// Free volatile memory on the card, in bytes.
  final int? freeVolatileMemory;

  factory CcidEuiccInfoResult.fromRaw(Map<String, dynamic> raw) =>
      CcidEuiccInfoResult(
        outcome: _parseOutcome(raw['outcome'] as String?),
        svn: raw['svn'] as String?,
        freeNonVolatileMemory: (raw['freeNonVolatileMemory'] as num?)?.toInt(),
        freeVolatileMemory: (raw['freeVolatileMemory'] as num?)?.toInt(),
      );
}

CcidEuiccInfoOutcome _parseOutcome(String? raw) => switch (raw) {
      'success' => CcidEuiccInfoOutcome.success,
      'read_failed' => CcidEuiccInfoOutcome.readFailed,
      'not_powered_on' => CcidEuiccInfoOutcome.notPoweredOn,
      'detached' => CcidEuiccInfoOutcome.detached,
      _ => CcidEuiccInfoOutcome.unknown,
    };
