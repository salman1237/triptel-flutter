/// FR-L911: the real, observed outcome of requesting the standard
/// per-device USB permission for a CCID reader -- never a prediction.
/// `denied` and `detachedMeanwhile` are genuinely different outcomes
/// (the user said no, vs. the reader vanished before they could
/// answer); `UsbCcidReaders.kt` disambiguates them on the native side
/// since the OS permission broadcast alone can't tell them apart.
enum CcidPermissionResult {
  granted,
  denied,
  detachedMeanwhile,
  exception,

  /// The native side returned a `result` string this Dart code doesn't
  /// recognize yet -- surfaced honestly rather than silently mapped to
  /// some other outcome.
  unknown,
}

CcidPermissionResult parseCcidPermissionResult(Map<String, dynamic> raw) =>
    switch (raw['result'] as String?) {
      'granted' => CcidPermissionResult.granted,
      'denied' => CcidPermissionResult.denied,
      'detached_meanwhile' => CcidPermissionResult.detachedMeanwhile,
      'exception' => CcidPermissionResult.exception,
      _ => CcidPermissionResult.unknown,
    };
