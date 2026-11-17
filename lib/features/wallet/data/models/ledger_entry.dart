import '../../../../core/money/money.dart';

/// `GET /wallets/ledger` row (API.md §5). `amount` is always a positive
/// magnitude -- sign/colour comes from [txType] (backend's own convention,
/// confirmed in `finance_svc.py`: credited = +amount, debited = -amount).
class LedgerEntry {
  const LedgerEntry({
    required this.txType,
    required this.amount,
    required this.balanceAfter,
    required this.referenceType,
    required this.description,
    required this.createdAt,
  });

  final String txType; // CREDIT | DEBIT
  final Money amount;
  final Money balanceAfter;
  final String referenceType;
  final String? description;
  final DateTime createdAt;

  bool get isCredit => txType == 'CREDIT';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        txType: json['tx_type'] as String,
        amount: Money.parseEur(json['amount'] as String),
        balanceAfter: Money.parseEur(json['balance_after'] as String),
        referenceType: json['reference_type'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Human labels for `reference_type` (FR-602). Falls back to the raw enum
/// value for any future type the backend adds before the app catches up.
const Map<String, String> ledgerReferenceLabels = {
  'DEPOSIT_GATEWAY': 'Wallet top-up',
  'DEPOSIT_MANUAL': 'Manual deposit',
  'ORDER_PURCHASE': 'eSIM purchase',
  'COMMISSION_EARNED': 'Commission earned',
  'ADMIN_ADJUSTMENT': 'Admin adjustment',
  'REFUND': 'Refund',
  'COMMISSION_TRANSFER': 'Commission transfer',
  'WITHDRAWAL_HOLD': 'Withdrawal requested',
  'WITHDRAWAL_REVERSED': 'Withdrawal reversed',
  'REWARD_EARNED': 'Reward credited',
  'REWARD_REVERSED': 'Reward reversed',
  'AGENT_COMMISSION_EARNED': 'Agent commission earned',
  'ESIM_TOPUP_PURCHASE': 'eSIM data top-up',
};

String ledgerReferenceLabel(String referenceType) =>
    ledgerReferenceLabels[referenceType] ?? referenceType;
