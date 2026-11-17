import '../../../core/money/money.dart';
import '../data/models/withdrawal_config.dart';

/// Client-side preview only -- the authoritative fee is computed server-side
/// at submission (`POST /withdrawals`). Mirrors the real backend's
/// `compute_fee` (`withdrawal_settings_svc.py`) exactly: PERCENT takes
/// `amount * feeValue / 100`; FLAT takes `feeValue` as a flat EUR amount;
/// either way the fee is capped at the amount itself (a fee can never
/// exceed what's being withdrawn, so net is never negative).
Money computeWithdrawalFee(WithdrawalConfig config, Money amount) {
  final feeEur = config.isPercentFee
      ? amount.eurValue * config.feeValue / 100
      : config.feeValue;
  final feeCents = (feeEur * 100).round();
  final capped = feeCents.clamp(0, amount.eurCents);
  return Money(capped);
}

Money computeWithdrawalNet(WithdrawalConfig config, Money amount) =>
    amount - computeWithdrawalFee(config, amount);
