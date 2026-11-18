import '../../esims/data/models/my_esim.dart';

/// FR-201b: which of the signed-in user's eSIMs (if any) earns the Home
/// hero's usage-summary-card treatment. `GET /orders/my-esims` is already
/// newest-first (API.md section 7), so the first entry whose `status` is
/// genuinely usable ('ACTIVE' or 'INSTALLED' -- the same "success" bucket
/// `esimStatusChip` already uses) is the most recently active one. A
/// 'RELEASED'/'ALLOCATED' eSIM isn't installed yet and has nothing real to
/// show in a usage ring; a terminal one (SUSPENDED/REVOKED/CANCELLED/
/// EXPIRED) is no longer "active" by any reading of the FR text.
MyEsim? activeEsimForHomeCard(List<MyEsim> esims) {
  for (final esim in esims) {
    if (esim.status == 'ACTIVE' || esim.status == 'INSTALLED') return esim;
  }
  return null;
}
