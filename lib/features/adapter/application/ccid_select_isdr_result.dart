/// FR-L913: the real, observed outcome of opening a logical channel
/// and selecting ISD-R by AID on it -- never a prediction. `success`
/// means a full round trip completed (channel opened, SELECT sent,
/// T=0 chaining resolved to a final status word); [swIsSuccess] is
/// whether that final status word was `9000` (the SELECT itself
/// worked), which is a separate question from whether the round trip
/// completed at all.
enum CcidSelectIsdROutcome {
  success,
  channelOpenFailed,
  selectFailed,
  notPoweredOn,

  /// The native side returned an `outcome` string this Dart code
  /// doesn't recognize yet -- surfaced honestly rather than silently
  /// mapped to some other outcome.
  unknown,
}

class CcidSelectIsdRResult {
  const CcidSelectIsdRResult({
    required this.outcome,
    this.channel,
    this.sw,
    this.swIsSuccess,
    this.fciHex,
    this.reason,
  });

  final CcidSelectIsdROutcome outcome;
  final int? channel;

  /// Hex-encoded status word (e.g. "9000"), only present on
  /// [CcidSelectIsdROutcome.success].
  final String? sw;
  final bool? swIsSuccess;

  /// Hex-encoded FCI (File Control Information) bytes the card
  /// returned, only present on [CcidSelectIsdROutcome.success].
  final String? fciHex;

  /// A plain-language reason, present on the failure outcomes.
  final String? reason;

  factory CcidSelectIsdRResult.fromRaw(Map<String, dynamic> raw) =>
      CcidSelectIsdRResult(
        outcome: _parseOutcome(raw['outcome'] as String?),
        channel: raw['channel'] as int?,
        sw: raw['sw'] as String?,
        swIsSuccess: raw['success'] as bool?,
        fciHex: raw['fciHex'] as String?,
        reason: raw['reason'] as String?,
      );
}

CcidSelectIsdROutcome _parseOutcome(String? raw) => switch (raw) {
      'success' => CcidSelectIsdROutcome.success,
      'channel_open_failed' => CcidSelectIsdROutcome.channelOpenFailed,
      'select_failed' => CcidSelectIsdROutcome.selectFailed,
      'not_powered_on' => CcidSelectIsdROutcome.notPoweredOn,
      _ => CcidSelectIsdROutcome.unknown,
    };
