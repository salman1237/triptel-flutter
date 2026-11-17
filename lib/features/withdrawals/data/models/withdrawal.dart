import '../../../../core/money/money.dart';

/// `POST /withdrawals` response (API.md §10) -- only the fields FR-702's own
/// confirmation needs; FR-703/704 (history/receipt) can extend this with
/// `note`/`account`/`payout_amount`/etc. when built. `amount`/`fee_amount`/
/// `net_amount` are EUR.
class Withdrawal {
  const Withdrawal({
    required this.referenceNo,
    required this.amount,
    required this.feeAmount,
    required this.netAmount,
    required this.accountLine,
    required this.status,
  });

  final String referenceNo;
  final Money amount;
  final Money feeAmount;
  final Money netAmount;
  final String accountLine;
  final String status; // PENDING | PAID | REJECTED | CANCELLED

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        referenceNo: json['reference_no'] as String,
        amount: Money.parseEur(json['amount'] as String),
        feeAmount: Money.parseEur(json['fee_amount'] as String),
        netAmount: Money.parseEur(json['net_amount'] as String),
        accountLine: json['account_line'] as String,
        status: json['status'] as String,
      );
}
