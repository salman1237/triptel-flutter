/// FR-406: "Daily breakdown & install history when present" -- VivaPe
/// only (API.md section 7), always empty for eSIM Access. Neither endpoint
/// documents a fixed item schema (the only documented field is `eid` on
/// history items, which the backend itself calls something the customer
/// "has no use for"), so entries are rendered generically rather than
/// guessing field names that might not match reality.
bool hasHistorySection(List<Map<String, dynamic>> history,
        List<Map<String, dynamic>> dailyBreakdown) =>
    history.isNotEmpty || dailyBreakdown.isNotEmpty;

/// One human-readable line per entry: "key: value" pairs, sorted for a
/// stable order, `eid` always excluded (a device identifier with nothing
/// useful to show the customer).
String formatHistoryEntry(Map<String, dynamic> entry) {
  final keys = entry.keys.where((k) => k != 'eid').toList()..sort();
  return keys.map((k) => '$k: ${entry[k]}').join(', ');
}
