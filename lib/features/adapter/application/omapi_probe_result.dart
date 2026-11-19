/// FR-L905: the real, observed outcome of trying to open an OMAPI
/// channel to the in-tray card's ISD-R applet -- never a prediction.
/// `available == true` means the card's own ARA-M access-control list
/// actually granted this app's certificate a channel; anything else is
/// a real "no," not an error to retry around.
enum OmapiProbeReason {
  channelOpened,
  araMDenied,
  noUiccReader,
  noSePresent,
  openSessionFailed,
  openChannelFailed,
  seServiceInitFailed,
  serviceConnectTimeout,
  omapiRequiresApi28,
  exception,

  /// The native side returned a `reason` string this Dart code doesn't
  /// recognize yet (e.g. after a native-side change) -- surfaced
  /// honestly rather than silently mapped to some other reason.
  unknown,
}

class OmapiProbeResult {
  const OmapiProbeResult({
    required this.available,
    required this.reason,
    this.readerNames = const [],
    this.error,
    this.selectResponseHex,
  });

  final bool available;
  final OmapiProbeReason reason;
  final List<String> readerNames;
  final String? error;

  /// The ISD-R `SELECT` response's raw bytes, hex-encoded -- only present
  /// when [available] is true. Not parsed further here; just evidence
  /// that a real APDU exchange happened.
  final String? selectResponseHex;

  factory OmapiProbeResult.fromRaw(Map<String, dynamic> raw) =>
      OmapiProbeResult(
        available: raw['available'] as bool? ?? false,
        reason: _parseReason(raw['reason'] as String?),
        readerNames: (raw['readerNames'] as List?)?.cast<String>() ?? const [],
        error: raw['error'] as String?,
        selectResponseHex: raw['selectResponseHex'] as String?,
      );

  /// A plain-language readout for the diagnostic screen -- states what
  /// was observed, not a recommendation or a next step.
  String summary() => switch (reason) {
        OmapiProbeReason.channelOpened =>
          "Channel opened -- this app's certificate is allowed by the "
              'card\'s access rules.',
        OmapiProbeReason.araMDenied =>
          "Denied: the card's access-control list (ARA-M) does not allow "
              "this app's certificate.",
        OmapiProbeReason.noUiccReader =>
          'No UICC/SIM-tray reader was found on this device.',
        OmapiProbeReason.noSePresent =>
          'A UICC reader exists but reports no card/secure element '
              'present.',
        OmapiProbeReason.openSessionFailed =>
          'Could not open a session with the card.',
        OmapiProbeReason.openChannelFailed =>
          'Could not open a channel to the card (not an access-control '
              'denial).',
        OmapiProbeReason.seServiceInitFailed =>
          'Could not start the Android Secure Element service.',
        OmapiProbeReason.serviceConnectTimeout =>
          'Timed out waiting for the Secure Element service to connect.',
        OmapiProbeReason.omapiRequiresApi28 =>
          "This device's Android version is too old for OMAPI (needs "
              'Android 9 / API 28+).',
        OmapiProbeReason.exception =>
          'An unexpected error occurred during the probe.',
        OmapiProbeReason.unknown =>
          'Unrecognized result from the native probe.',
      };
}

OmapiProbeReason _parseReason(String? raw) => switch (raw) {
      'channel_opened' => OmapiProbeReason.channelOpened,
      'ara_m_denied' => OmapiProbeReason.araMDenied,
      'no_uicc_reader' => OmapiProbeReason.noUiccReader,
      'no_se_present' => OmapiProbeReason.noSePresent,
      'open_session_failed' => OmapiProbeReason.openSessionFailed,
      'open_channel_failed' => OmapiProbeReason.openChannelFailed,
      'se_service_init_failed' => OmapiProbeReason.seServiceInitFailed,
      'service_connect_timeout' => OmapiProbeReason.serviceConnectTimeout,
      'omapi_requires_api28' => OmapiProbeReason.omapiRequiresApi28,
      'exception' => OmapiProbeReason.exception,
      _ => OmapiProbeReason.unknown,
    };
