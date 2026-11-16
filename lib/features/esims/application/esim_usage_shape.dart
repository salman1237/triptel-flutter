import '../data/models/esim_status.dart';

/// FR-403's usage ring fraction. `usedPct` is a 0-100 percentage from the
/// API; unlimited plans have no allowance at all (Rules.md) -- no ring fill.
double? usageFraction(EsimUsageInfo usage) {
  final pct = usage.usedPct;
  if (usage.isUnlimited || pct == null) return null;
  return (pct / 100).clamp(0, 1);
}

/// The ring's center text: remaining data, or "Unlimited".
String usageCenterText(EsimUsageInfo usage) {
  if (usage.isUnlimited) return 'Unlimited';
  return usage.remainingFormatted;
}

/// FR-403: "validity countdown or 'starts on install' note". A pure
/// function of the validity info and the current time (injected so this
/// stays deterministic in tests) -- never infers activation from any other
/// field (Rules.md).
String validityCountdownLabel(EsimValidityInfo validity, DateTime now) {
  if (validity.activatedAt == null) return 'Validity starts on install';
  final expires = validity.expiresAt;
  if (expires == null) return '${validity.days}-day validity';
  final daysLeft = expires.difference(now).inDays;
  if (daysLeft <= 0) return 'Expires today';
  return daysLeft == 1 ? '1 day left' : '$daysLeft days left';
}

/// FR-403: `telemetry.error` non-null -> "Live usage temporarily
/// unavailable" -- never a hard failure, the server already returned the
/// last good snapshot alongside it.
bool showsTelemetryStaleBanner(EsimTelemetryInfo telemetry) =>
    telemetry.error != null;

/// FR-403: the manual refresh button's 30s cooldown, client-side on top of
/// the server's own per-eSIM rate limit. Pure function of "now" so tests
/// don't depend on real time passing.
Duration refreshCooldownRemaining(
  DateTime? lastRefreshedAt,
  DateTime now, {
  Duration cooldown = const Duration(seconds: 30),
}) {
  if (lastRefreshedAt == null) return Duration.zero;
  final elapsed = now.difference(lastRefreshedAt);
  final remaining = cooldown - elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}
