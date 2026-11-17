import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/withdrawal_status_chip.dart';
import '../application/withdrawals_providers.dart';
import '../data/models/withdrawal.dart';

/// FR-703: withdrawal history. `GET /withdrawals`, status chips, cancel
/// while pending (`POST /withdrawals/{id}/cancel`). No endpoint detail view
/// exists yet -- FR-704 (receipt) is a separate, not-yet-built screen, so
/// rows here aren't tappable beyond the Cancel action.
class WithdrawalHistoryScreen extends ConsumerWidget {
  const WithdrawalHistoryScreen({super.key});

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, Withdrawal withdrawal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this withdrawal?'),
        content: Text(withdrawal.referenceNo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const ValueKey('withdrawal-cancel-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(withdrawalsApiProvider).cancelWithdrawal(withdrawal.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    ref.invalidate(withdrawalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(withdrawalsProvider);
    final rate = ref.watch(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.watch(currencyPreferenceProvider).valueOrNull;

    String money(Money amount) => rate == null || code == null
        ? ''
        : formatMoney(amount, currencyCode: code, rateToBase: rate);

    return TriptelScaffold(
      key: const ValueKey('withdrawal-history-screen'),
      appBar: AppBar(title: const Text('Withdrawal history')),
      scrollable: false,
      body: switch (withdrawalsAsync) {
        AsyncData(:final value) => value.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.history,
                  message: 'No withdrawal requests yet.',
                ),
              )
            : ListView.separated(
                itemCount: value.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.line),
                itemBuilder: (context, i) => _WithdrawalRow(
                  withdrawal: value[i],
                  amountText: money(value[i].amount),
                  onCancel: () => _confirmCancel(context, ref, value[i]),
                ),
              ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your withdrawal history.",
              onRetry: () => ref.invalidate(withdrawalsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({
    required this.withdrawal,
    required this.amountText,
    required this.onCancel,
  });

  final Withdrawal withdrawal;
  final String amountText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final chip = withdrawalStatusChip(withdrawal.status);
    return Padding(
      key: ValueKey('withdrawal-row-${withdrawal.id}'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(withdrawal.referenceNo, style: AppTypography.body()),
              ),
              Text(amountText, style: AppTypography.body()),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StatusChip(label: chip.label, tone: chip.tone),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMd().format(withdrawal.createdAt.toLocal()),
                style: AppTypography.caption(color: AppColors.inkMuted),
              ),
            ],
          ),
          if (withdrawal.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text(withdrawal.rejectionReason!,
                style: AppTypography.caption(color: AppColors.danger)),
          ],
          if (withdrawal.status == 'PENDING') ...[
            const SizedBox(height: 8),
            PillButton(
              key: ValueKey('withdrawal-cancel-${withdrawal.id}'),
              label: 'Cancel',
              variant: PillButtonVariant.text,
              fullWidth: false,
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }
}
