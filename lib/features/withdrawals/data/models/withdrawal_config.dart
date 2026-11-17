import '../../../../core/money/money.dart';

/// `GET /withdrawals/config` (API.md §10). `min_amount`/`max_amount`/
/// `balance` are EUR; `fee_value` is either a flat EUR amount or a percent
/// number depending on [feeType] -- see `withdrawal_fee.dart`'s
/// `computeWithdrawalFee`. `fee_type` is compared case-insensitively: the
/// real backend source (`withdrawal_settings_svc.py`) stores/returns it
/// lowercase ("flat"/"percent"), while API.md documents it uppercase.
class WithdrawalConfig {
  const WithdrawalConfig({
    required this.minAmount,
    required this.maxAmount,
    required this.feeType,
    required this.feeValue,
    required this.payoutCurrency,
    required this.processingTime,
    required this.isEnabled,
    required this.balance,
    required this.canWithdraw,
    required this.blockers,
    required this.kycVerified,
    this.kycStatus,
    required this.accountCount,
    required this.noteCategories,
  });

  final Money minAmount;
  final Money maxAmount;
  final String feeType; // flat | percent (case-insensitive)
  final double feeValue;
  final String payoutCurrency;
  final String processingTime;
  final bool isEnabled;
  final Money balance;
  final bool canWithdraw;
  final List<String> blockers;
  final bool kycVerified;
  final String? kycStatus;
  final int accountCount;
  final List<String> noteCategories;

  bool get isPercentFee => feeType.toUpperCase() == 'PERCENT';

  factory WithdrawalConfig.fromJson(Map<String, dynamic> json) =>
      WithdrawalConfig(
        minAmount: Money.parseEur(json['min_amount'] as String),
        maxAmount: Money.parseEur(json['max_amount'] as String),
        feeType: json['fee_type'] as String,
        feeValue: double.parse(json['fee_value'] as String),
        payoutCurrency: json['payout_currency'] as String,
        processingTime: json['processing_time'] as String,
        isEnabled: json['is_enabled'] as bool,
        balance: Money.parseEur(json['balance'] as String),
        canWithdraw: json['can_withdraw'] as bool,
        blockers: (json['blockers'] as List).cast<String>(),
        kycVerified: json['kyc_verified'] as bool,
        kycStatus: json['kyc_status'] as String?,
        accountCount: json['account_count'] as int,
        noteCategories: (json['note_categories'] as List).cast<String>(),
      );
}
