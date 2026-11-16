import 'package:intl/intl.dart';

import '../../../core/widgets/status_chip.dart';
import '../data/models/my_esim.dart';

/// FR-402's card data line. `dataAmountGb`/`validityDays` here are the
/// ORIGINAL purchase totals (API.md section 7 -- stale after a top-up;
/// FR-403's `/esims/{id}/status` has the real current totals), so this list
/// view only ever shows the plan as originally bought, never a per-day
/// Day Pass breakdown (this endpoint carries no plan-shape data to detect
/// that with).
String esimDataLabel(MyEsim esim) {
  if (esim.isUnlimited) return 'Unlimited';
  final gb = esim.dataAmountGb;
  if (gb < 1) return '${(gb * 1000).round()} MB';
  final rounded = (gb * 100).round() / 100;
  var text = rounded.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return '$text GB';
}

/// FR-402: "'starts on install' or expiry" -- `activated_at`/`expires_at`
/// stay null until installed (API.md section 7, Rules.md), so that's the
/// only signal used; never a computed countdown (FR-403's job, once this
/// eSIM's real current status is known).
String esimValidityLabel(MyEsim esim) {
  if (esim.activatedAt == null) return 'Validity starts on install';
  final expires = esim.expiresAt;
  if (expires == null) return '${esim.validityDays}-day validity';
  return 'Expires ${DateFormat.yMMMd().format(expires.toLocal())}';
}

/// FR-402: "Bought for me" vs "Bought by me" (`is_beneficiary`).
String esimOwnershipLabel(MyEsim esim) =>
    esim.isBeneficiary ? 'Bought for me' : 'Bought by me';

/// Design_System.md's StatusChip tones: "Active/Installed success, Not
/// installed sky, Preparing warning, Suspended/Revoked/Cancelled/Expired/
/// Failed danger." `RELEASED` deliberately says "Ready to install", not
/// "Not installed": this list's own `status` field doesn't track real
/// install state on this backend (confirmed live -- an eSIM can stay
/// `RELEASED` here even once `GET /esims/{id}/status`'s telemetry
/// `is_installed` is genuinely true), so the chip must not claim to know
/// something it doesn't (Rules.md: "Treat only telemetry `is_installed`
/// as installed"). The real, telemetry-backed label lives on the detail
/// screen (FR-403's `status.label`, sourced from that richer endpoint).
({String label, StatusTone tone}) esimStatusChip(String status) =>
    switch (status) {
      'ACTIVE' => (label: 'Active', tone: StatusTone.success),
      'INSTALLED' => (label: 'Installed', tone: StatusTone.success),
      'RELEASED' => (label: 'Ready to install', tone: StatusTone.info),
      'ALLOCATED' => (label: 'Preparing', tone: StatusTone.warning),
      'SUSPENDED' => (label: 'Suspended', tone: StatusTone.danger),
      'REVOKED' => (label: 'Revoked', tone: StatusTone.danger),
      'CANCELLED' => (label: 'Cancelled', tone: StatusTone.danger),
      'EXPIRED' => (label: 'Expired', tone: StatusTone.danger),
      _ => (label: status, tone: StatusTone.warning),
    };
