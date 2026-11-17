import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money/currency_format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../esims/application/receipt_sharer.dart';
import '../application/withdrawal_status_chip.dart';
import '../application/withdrawals_providers.dart';

/// FR-704: a printable/shareable receipt for one withdrawal -- reference,
/// amounts (EUR), the frozen payout rate/amount (in `payout_currency`,
/// null until approved -- shown as "pending approval" rather than guessed),
/// and the account line. Reuses FR-409's generic [receiptSharerProvider]
/// (a [RepaintBoundary] -> PNG -> native share sheet), same reasoning as
/// that screen: no new PDF dependency needed.
class WithdrawalReceiptScreen extends ConsumerStatefulWidget {
  const WithdrawalReceiptScreen({super.key, required this.withdrawalId});

  final String withdrawalId;

  @override
  ConsumerState<WithdrawalReceiptScreen> createState() =>
      _WithdrawalReceiptScreenState();
}

class _WithdrawalReceiptScreenState
    extends ConsumerState<WithdrawalReceiptScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ref.read(receiptSharerProvider)(_boundaryKey);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalAsync = ref.watch(withdrawalProvider(widget.withdrawalId));

    return TriptelScaffold(
      key: const ValueKey('withdrawal-receipt-screen'),
      appBar: AppBar(title: const Text('Withdrawal receipt')),
      body: switch (withdrawalAsync) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  key: const ValueKey('withdrawal-receipt-card'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Triptel',
                          style:
                              AppTypography.headline(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(value.referenceNo,
                                style: AppTypography.title()),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: withdrawalStatusChip(value.status).label,
                            tone: withdrawalStatusChip(value.status).tone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(value.createdAt.toLocal()),
                        style: AppTypography.caption(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 20),
                      _ReceiptRow(
                          label: 'Amount',
                          value:
                              '€${value.amount.eurValue.toStringAsFixed(2)}'),
                      _ReceiptRow(
                          label: 'Fee',
                          value:
                              '€${value.feeAmount.eurValue.toStringAsFixed(2)}'),
                      _ReceiptRow(
                          label: 'Net amount',
                          value:
                              '€${value.netAmount.eurValue.toStringAsFixed(2)}'),
                      if (value.conversionRate != null)
                        _ReceiptRow(
                            label: 'Rate',
                            value:
                                '1 EUR = ${value.conversionRate!.toStringAsFixed(4)} '
                                '${value.payoutCurrency ?? ''}'),
                      _ReceiptRow(
                        label: 'Payout',
                        value: value.payoutAmount != null &&
                                value.payoutCurrency != null
                            ? formatRawAmount(value.payoutAmount!,
                                currencyCode: value.payoutCurrency!)
                            : 'Pending approval',
                      ),
                      _ReceiptRow(label: 'Account', value: value.accountLine),
                      if (value.paymentReference != null)
                        _ReceiptRow(
                            label: 'Payment ref.',
                            value: value.paymentReference!),
                      if (value.rejectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            value.rejectionReason!,
                            style:
                                AppTypography.caption(color: AppColors.danger),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PillButton(
                key: const ValueKey('withdrawal-receipt-share-button'),
                label: _sharing ? 'Preparing...' : 'Share receipt',
                onPressed: _sharing ? null : _share,
              ),
            ],
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load this withdrawal's receipt.",
              onRetry: () =>
                  ref.invalidate(withdrawalProvider(widget.withdrawalId)),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption(color: AppColors.inkMuted)),
          Flexible(
            child: Text(value,
                style: AppTypography.body(), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
