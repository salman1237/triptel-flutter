/// `POST /wallets/manual-deposit` response (API.md §5). No customer upload
/// endpoint for a receipt image exists -- `receipt_url` is never sent.
class ManualDeposit {
  const ManualDeposit({
    required this.amount,
    required this.currency,
    required this.bankName,
    required this.transactionId,
    required this.status,
  });

  final String amount;
  final String currency;
  final String bankName;
  final String transactionId;

  /// Always "PENDING" on submission -- no endpoint lists past deposits
  /// (API.md §5), so this is the only status the app ever sees directly.
  final String status;

  factory ManualDeposit.fromJson(Map<String, dynamic> json) => ManualDeposit(
        amount: json['amount'] as String,
        currency: json['currency'] as String,
        bankName: json['bank_name'] as String,
        transactionId: json['transaction_id'] as String,
        status: json['status'] as String,
      );
}
