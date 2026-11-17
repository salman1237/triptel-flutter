import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/wallet_providers.dart';
import '../data/models/ledger_entry.dart';

/// FR-602: transaction history. `GET /wallets/ledger`, filterable by wallet
/// type, human labels for `reference_type`, credit/debit colouring.
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  static const _filters = <String?>[null, 'DEFAULT', 'REWARD', 'COMMISSION'];
  static const _filterLabels = ['All', 'Main', 'Reward', 'Commission'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final rate = ref.watch(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.watch(currencyPreferenceProvider).valueOrNull;

    String amountText(Money amount) {
      if (rate == null || code == null) return '';
      return formatMoney(amount, currencyCode: code, rateToBase: rate);
    }

    return TriptelScaffold(
      key: const ValueKey('ledger-screen'),
      appBar: AppBar(title: const Text('Transaction history')),
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Scrollable, not full-width: 4 segments (All/Main/Reward/
          // Commission) don't fit SegmentedPill's fixed per-segment padding
          // on a narrow screen -- found live on-device (the longest label
          // overflowed its pill track) while verifying this feature.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedPill(
              options: _filterLabels,
              selectedIndex: _filters.indexOf(filter),
              onChanged: (i) =>
                  ref.read(ledgerFilterProvider.notifier).state = _filters[i],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: switch (ledgerAsync) {
              AsyncData(:final value) => value.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No transactions yet. Activity on this '
                            'wallet will show up here.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: value.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, i) =>
                          _LedgerRow(entry: value[i], amountText: amountText),
                    ),
              AsyncError() => Center(
                  child: ErrorState(
                    message: "We couldn't load your transaction history.",
                    onRetry: () => ref.invalidate(ledgerProvider),
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.amountText});

  final LedgerEntry entry;
  final String Function(Money) amountText;

  @override
  Widget build(BuildContext context) {
    final color = entry.isCredit ? AppColors.success : AppColors.danger;
    final sign = entry.isCredit ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ledgerReferenceLabel(entry.referenceType),
                    style: AppTypography.body()),
                if (entry.description != null && entry.description!.isNotEmpty)
                  Text(entry.description!,
                      style: AppTypography.caption(color: AppColors.inkMuted)),
                Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format(entry.createdAt.toLocal()),
                    style: AppTypography.caption(color: AppColors.inkMuted)),
              ],
            ),
          ),
          Text('$sign${amountText(entry.amount)}',
              style: AppTypography.body(color: color)),
        ],
      ),
    );
  }
}
