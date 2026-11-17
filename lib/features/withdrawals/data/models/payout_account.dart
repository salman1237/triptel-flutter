/// `GET/POST /withdrawals/accounts` row (API.md §10).
class PayoutAccount {
  const PayoutAccount({
    required this.id,
    required this.accountType,
    required this.bankName,
    required this.holderName,
    required this.accountNumber,
    this.branchName,
    this.routingNumber,
    required this.isDefault,
  });

  final String id;
  final String accountType; // BANK | MOBILE
  final String bankName;
  final String holderName;
  final String accountNumber;
  final String? branchName;
  final String? routingNumber;
  final bool isDefault;

  factory PayoutAccount.fromJson(Map<String, dynamic> json) => PayoutAccount(
        id: json['id'] as String,
        accountType: json['account_type'] as String,
        bankName: json['bank_name'] as String,
        holderName: json['holder_name'] as String,
        accountNumber: json['account_number'] as String,
        branchName: json['branch_name'] as String?,
        routingNumber: json['routing_number'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );
}
