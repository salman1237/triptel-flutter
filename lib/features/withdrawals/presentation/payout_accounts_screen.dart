import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/withdrawals_providers.dart';
import '../data/models/payout_account.dart';

const _maxAccounts = 5;

/// FR-701: list / add / set default / delete payout accounts (max 5).
class PayoutAccountsScreen extends ConsumerWidget {
  const PayoutAccountsScreen({super.key});

  Future<void> _openActions(
      BuildContext context, WidgetRef ref, PayoutAccount account) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!account.isDefault)
              ListTile(
                key: const ValueKey('payout-account-set-default'),
                leading:
                    const Icon(Icons.star_outline, color: AppColors.primary),
                title: const Text('Set as default'),
                onTap: () => Navigator.of(sheetContext).pop('default'),
              ),
            ListTile(
              key: const ValueKey('payout-account-delete'),
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'default') {
      await _setDefault(context, ref, account);
    } else if (action == 'delete') {
      await _confirmDelete(context, ref, account);
    }
  }

  Future<void> _setDefault(
      BuildContext context, WidgetRef ref, PayoutAccount account) async {
    try {
      await ref.read(withdrawalsApiProvider).setDefaultAccount(account.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    ref.invalidate(payoutAccountsProvider);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PayoutAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this account?'),
        content: Text('${account.bankName} · ${account.accountNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('payout-account-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(withdrawalsApiProvider).deleteAccount(account.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    ref.invalidate(payoutAccountsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(payoutAccountsProvider);

    return TriptelScaffold(
      key: const ValueKey('payout-accounts-screen'),
      appBar: AppBar(title: const Text('Payout accounts')),
      scrollable: false,
      body: switch (accountsAsync) {
        AsyncData(:final value) => _Body(
            accounts: value,
            onAccountTap: (account) => _openActions(context, ref, account),
            onAdd: () => context.push('/wallet/withdraw/accounts/add'),
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your payout accounts.",
              onRetry: () => ref.invalidate(payoutAccountsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.accounts,
    required this.onAccountTap,
    required this.onAdd,
  });

  final List<PayoutAccount> accounts;
  final ValueChanged<PayoutAccount> onAccountTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          const Expanded(
            child: Center(
              child: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'No payout accounts yet. Add one to request a '
                    'withdrawal.',
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final account = accounts[i];
                return _AccountCard(
                  key: ValueKey('payout-account-${account.id}'),
                  account: account,
                  onTap: () => onAccountTap(account),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        PillButton(
          key: const ValueKey('payout-account-add-button'),
          label: accounts.length >= _maxAccounts
              ? 'Maximum $_maxAccounts accounts saved'
              : 'Add payout account',
          onPressed: accounts.length >= _maxAccounts ? null : onAdd,
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({super.key, required this.account, required this.onTap});

  final PayoutAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [appCardShadow],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(account.bankName, style: AppTypography.body()),
                      if (account.isDefault) ...[
                        const SizedBox(width: 8),
                        const StatusChip(
                            label: 'Default', tone: StatusTone.success),
                      ],
                    ],
                  ),
                  Text(
                    '${account.holderName} · ${account.accountNumber}',
                    style: AppTypography.caption(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
