import '../../../../core/money/money.dart';

/// `GET /wallets/my-wallets` row (API.md §5). Every wallet amount is EUR
/// (API.md §0.2), so `currency` is never read, same as [Product.retailPrice].
class Wallet {
  const Wallet({
    required this.walletType,
    required this.balance,
    required this.isFrozen,
  });

  final String walletType; // DEFAULT | REWARD | COMMISSION
  final Money balance;
  final bool isFrozen;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        walletType: json['wallet_type'] as String,
        balance: Money.parseEur(json['balance'] as String),
        isFrozen: json['is_frozen'] as bool? ?? false,
      );
}
