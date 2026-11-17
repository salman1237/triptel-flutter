import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/widgets.dart';
import '../application/wallet_balance.dart';
import '../application/wallet_providers.dart';
import '../data/models/wallet.dart';

/// FR-601: wallet overview. Gradient balance card (Design_System.md §1/§2,
/// reusing the pre-existing, previously-unused-in-a-real-feature
/// `BalanceCard`) -- Main balance (DEFAULT), Reward credit (REWARD,
/// "not withdrawable"), Commission only shown when > 0 (a customer never
/// earns commission unless they're also a partner/agent, Rules.md/API.md
/// section 5). Actions Top up (FR-603) · Withdraw (FR-701+) · Refer
/// (FR-801+) -- none of those exist yet, so each shows a "coming soon"
/// note instead of a dead tap, same precedent as every other
/// not-yet-built forward dependency this session.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  String _formatMoney(double? rate, String? code, Money amount) {
    if (rate == null || code == null) return '';
    return formatMoney(amount, currencyCode: code, rateToBase: rate);
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(myWalletsProvider);
    // Watched (not just read) so this screen rebuilds once these resolve --
    // nothing else on this tab watches them to trigger that first fetch.
    final rate = ref.watch(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.watch(currencyPreferenceProvider).valueOrNull;

    return TriptelScaffold(
      key: const ValueKey('wallet-tab'),
      body: switch (walletsAsync) {
        AsyncData(:final value) => _Body(
            wallets: value,
            formatMoney: (amount) => _formatMoney(rate, code, amount),
            onTopUp: () => _comingSoon(context, 'Top up'),
            onWithdraw: () => _comingSoon(context, 'Withdraw'),
            onRefer: () => _comingSoon(context, 'Refer a friend'),
            onViewHistory: () => context.push('/wallet/history'),
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your wallet.",
              onRetry: () => ref.invalidate(myWalletsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.wallets,
    required this.formatMoney,
    required this.onTopUp,
    required this.onWithdraw,
    required this.onRefer,
    required this.onViewHistory,
  });

  final List<Wallet> wallets;
  final String Function(Money) formatMoney;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final VoidCallback onRefer;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final commission = walletBalance(wallets, 'COMMISSION');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        BalanceCard(
          key: const ValueKey('wallet-balance-card'),
          title: 'Main balance',
          amountText: formatMoney(walletBalance(wallets, 'DEFAULT')),
          stats: [
            (
              'Reward credit (not withdrawable)',
              formatMoney(walletBalance(wallets, 'REWARD'))
            ),
            if (commission.eurCents > 0)
              ('Commission', formatMoney(commission)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: PillButton(
                key: const ValueKey('wallet-topup-button'),
                label: 'Top up',
                variant: PillButtonVariant.secondary,
                onPressed: onTopUp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                key: const ValueKey('wallet-withdraw-button'),
                label: 'Withdraw',
                variant: PillButtonVariant.secondary,
                onPressed: onWithdraw,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                key: const ValueKey('wallet-refer-button'),
                label: 'Refer',
                variant: PillButtonVariant.secondary,
                onPressed: onRefer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PillButton(
          key: const ValueKey('wallet-view-history-button'),
          label: 'View transaction history',
          variant: PillButtonVariant.text,
          fullWidth: false,
          onPressed: onViewHistory,
        ),
      ],
    );
  }
}
