/// `/settings/public.payment_methods[]` (API.md §1) -- manual-deposit
/// destinations; only active ones are returned by the backend already.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.kind,
    this.accountName,
    this.accountNumber,
    this.branch,
    this.instructions,
    this.isActive = true,
  });

  final String id;

  /// `POST /wallets/manual-deposit`'s `bank_name` must equal this exactly.
  final String name;

  final String kind;
  final String? accountName;
  final String? accountNumber;
  final String? branch;
  final String? instructions;
  final bool isActive;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String? ?? '',
        accountName: json['account_name'] as String?,
        accountNumber: json['account_number'] as String?,
        branch: json['branch'] as String?,
        instructions: json['instructions'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}
