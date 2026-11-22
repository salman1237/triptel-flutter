/// FR-L914: the real, observed outcome of reading the EID (eUICC ID)
/// via lpac's `euicc/` -- never a prediction. The EID stays on-device
/// (`docs/Rules.md`: "EID, ICCIDs and card info stay on the device" --
/// never sent to any Triptel endpoint); the UI masks it by default.
enum CcidReadEidOutcome {
  success,
  readFailed,
  notPoweredOn,

  /// The native side returned an `outcome` string this Dart code
  /// doesn't recognize yet -- surfaced honestly rather than silently
  /// mapped to some other outcome.
  unknown,
}

class CcidReadEidResult {
  const CcidReadEidResult({required this.outcome, this.eid});

  final CcidReadEidOutcome outcome;

  /// The real EID, only present on [CcidReadEidOutcome.success].
  final String? eid;

  factory CcidReadEidResult.fromRaw(Map<String, dynamic> raw) =>
      CcidReadEidResult(
        outcome: _parseOutcome(raw['outcome'] as String?),
        eid: raw['eid'] as String?,
      );
}

CcidReadEidOutcome _parseOutcome(String? raw) => switch (raw) {
      'success' => CcidReadEidOutcome.success,
      'read_failed' => CcidReadEidOutcome.readFailed,
      'not_powered_on' => CcidReadEidOutcome.notPoweredOn,
      _ => CcidReadEidOutcome.unknown,
    };
