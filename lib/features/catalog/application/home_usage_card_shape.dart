import '../../esims/data/models/my_esim.dart';

/// FR-201b: which of the signed-in user's eSIMs (if any) earns the Home
/// hero's usage-summary-card treatment. **Deliberately does NOT key off
/// `MyEsim.status`**: the earlier FR-403 session finding (claude-
/// progress.md, confirmed live) is that `GET /orders/my-esims`'s own
/// `status` enum "never updates" for eSIM Access profiles -- it can sit on
/// `RELEASED` forever even once the eSIM is genuinely installed and in
/// active use. `activatedAt`, from the same endpoint, is the field that
/// actually tracks real install state (it's what
/// `esimValidityLabel` already trusts over `status` to decide "Expires
/// ..." vs "Validity starts on install") -- so "active" here means
/// genuinely activated (`activatedAt != null`) and not yet expired.
/// `GET /orders/my-esims` is already newest-first (API.md section 7), so
/// the first qualifying entry is the most recently active one.
MyEsim? activeEsimForHomeCard(List<MyEsim> esims, DateTime now) {
  for (final esim in esims) {
    if (esim.activatedAt == null) continue;
    final expires = esim.expiresAt;
    if (expires != null && !expires.isAfter(now)) continue;
    return esim;
  }
  return null;
}
