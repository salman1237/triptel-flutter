import '../../../../core/money/money.dart';

/// `POST /withdrawals` / `GET /withdrawals` / `GET /withdrawals/{id}` /
/// `POST /withdrawals/{id}/cancel` response (API.md §10). `amount`/
/// `fee_amount`/`net_amount` are EUR; `payout_amount` is in
/// [payoutCurrency], frozen at approval -- FR-704 (receipt) can extend this
/// further with `note`/`account` snapshot/`has_proof` when built.
class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.referenceNo,
    required this.amount,
    required this.feeAmount,
    required this.netAmount,
    required this.accountLine,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  final String id;
  final String referenceNo;
  final Money amount;
  final Money feeAmount;
  final Money netAmount;
  final String accountLine;
  final String status; // PENDING | PAID | REJECTED | CANCELLED
  final DateTime createdAt;
  final String? rejectionReason;

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: json['id'] as String,
        referenceNo: json['reference_no'] as String,
        amount: Money.parseEur(json['amount'] as String),
        feeAmount: Money.parseEur(json['fee_amount'] as String),
        netAmount: Money.parseEur(json['net_amount'] as String),
        accountLine: json['account_line'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        rejectionReason: json['rejection_reason'] as String?,
      );
}
