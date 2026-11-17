import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/withdrawal_fee.dart';
import '../application/withdrawals_providers.dart';
import '../data/models/payout_account.dart';
import '../data/models/withdrawal_config.dart';

/// FR-702: withdrawal request. `GET /withdrawals/config` drives
/// blockers/limits/fee terms; `blockers` are shown verbatim (API.md §10).
/// If KYC is the (or a) blocker, offer "Verify now" -- FR-1002 isn't built
/// yet, so that's a "coming soon" placeholder like every other forward
/// dependency this session, same as "Add a payout account" linking to the
/// real FR-701 screen when `account_count == 0`.
class WithdrawalRequestScreen extends ConsumerStatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  ConsumerState<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState
    extends ConsumerState<WithdrawalRequestScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PayoutAccount? _selectedAccount;
  String? _selectedCategory;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Rebuilds the fee/net preview live as the user types.
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _comingSoon(String feature) => _showMessage('$feature is coming soon.');

  Future<void> _chooseAccount(List<PayoutAccount> accounts) async {
    final id = await PaymentMethodSheet.show(
      context,
      [
        for (final a in accounts)
          PaymentMethodOption(
            id: a.id,
            label: a.bankName,
            subtitle: a.accountNumber,
            icon: Icons.account_balance,
          ),
      ],
    );
    if (id == null) return;
    setState(() => _selectedAccount = accounts.firstWhere((a) => a.id == id));
  }

  Future<void> _submit(WithdrawalConfig config) async {
    final account = _selectedAccount;
    if (account == null) {
      _showMessage('Choose a payout account first.');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Enter an amount greater than zero.');
      return;
    }
    final amountMoney = Money((amount * 100).round());
    if (amountMoney < config.minAmount || amountMoney > config.maxAmount) {
      _showMessage(
          'Enter an amount between the minimum and maximum withdrawal.');
      return;
    }
    if (_noteController.text.length > 500) {
      _showMessage('Note must be 500 characters or fewer.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final withdrawal =
          await ref.read(withdrawalsApiProvider).createWithdrawal(
                amount: amount,
                bankAccountId: account.id,
                noteCategory: _selectedCategory,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              );
      if (!mounted) return;
      setState(() => _submitting = false);
      ref.invalidate(withdrawalConfigProvider);
      _showMessage(
          'Withdrawal ${withdrawal.referenceNo} requested -- ${withdrawal.status.toLowerCase()}.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.mustChangePassword) {
        context.push('/set-password');
        return;
      }
      _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(withdrawalConfigProvider);

    return TriptelScaffold(
      key: const ValueKey('withdrawal-request-screen'),
      appBar: AppBar(title: const Text('Request withdrawal')),
      body: switch (configAsync) {
        AsyncData(:final value) => value.blockers.isNotEmpty
            ? _BlockersView(
                config: value,
                onVerifyKyc: () => _comingSoon('KYC verification'),
                onManageAccounts: () =>
                    context.push('/wallet/withdraw/accounts'),
              )
            : _RequestForm(
                config: value,
                amountController: _amountController,
                noteController: _noteController,
                selectedAccount: _selectedAccount,
                selectedCategory: _selectedCategory,
                submitting: _submitting,
                onChooseAccount: () async {
                  final accounts =
                      await ref.read(payoutAccountsProvider.future);
                  if (context.mounted) await _chooseAccount(accounts);
                },
                onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                onManageAccounts: () =>
                    context.push('/wallet/withdraw/accounts'),
                onSubmit: () => _submit(value),
                onViewHistory: () => context.push('/wallet/withdraw/history'),
              ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load withdrawal settings.",
              onRetry: () => ref.invalidate(withdrawalConfigProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _BlockersView extends StatelessWidget {
  const _BlockersView({
    required this.config,
    required this.onVerifyKyc,
    required this.onManageAccounts,
  });

  final WithdrawalConfig config;
  final VoidCallback onVerifyKyc;
  final VoidCallback onManageAccounts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: AppColors.warning, size: 32),
            const SizedBox(height: 16),
            for (final blocker in config.blockers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  blocker,
                  key: const ValueKey('withdrawal-blocker'),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(),
                ),
              ),
            const SizedBox(height: 16),
            if (!config.kycVerified)
              PillButton(
                key: const ValueKey('withdrawal-verify-kyc-button'),
                label: 'Verify now',
                fullWidth: false,
                onPressed: onVerifyKyc,
              ),
            if (config.accountCount == 0) ...[
              const SizedBox(height: 12),
              PillButton(
                key: const ValueKey('withdrawal-add-account-button'),
                label: 'Add a payout account',
                variant: PillButtonVariant.secondary,
                fullWidth: false,
                onPressed: onManageAccounts,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestForm extends ConsumerWidget {
  const _RequestForm({
    required this.config,
    required this.amountController,
    required this.noteController,
    required this.selectedAccount,
    required this.selectedCategory,
    required this.submitting,
    required this.onChooseAccount,
    required this.onCategoryChanged,
    required this.onManageAccounts,
    required this.onSubmit,
    required this.onViewHistory,
  });

  final WithdrawalConfig config;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final PayoutAccount? selectedAccount;
  final String? selectedCategory;
  final bool submitting;
  final VoidCallback onChooseAccount;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onManageAccounts;
  final VoidCallback onSubmit;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = ref.watch(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.watch(currencyPreferenceProvider).valueOrNull;

    String money(Money amount) => rate == null || code == null
        ? ''
        : formatMoney(amount, currencyCode: code, rateToBase: rate);

    final amount = double.tryParse(amountController.text);
    final amountMoney = amount != null ? Money((amount * 100).round()) : null;
    final fee =
        amountMoney != null ? computeWithdrawalFee(config, amountMoney) : null;
    final net =
        amountMoney != null ? computeWithdrawalNet(config, amountMoney) : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Available: ${money(config.balance)} · Between '
            '${money(config.minAmount)} and ${money(config.maxAmount)} · '
            '${config.processingTime}',
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('withdrawal-amount-field'),
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount ($code)'),
          ),
          if (fee != null && net != null) ...[
            const SizedBox(height: 8),
            Text('Fee: ${money(fee)} · You receive: ${money(net)}',
                style: AppTypography.caption(color: AppColors.inkMuted)),
          ],
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey('withdrawal-choose-account-button'),
            label: selectedAccount == null
                ? 'Choose payout account'
                : '${selectedAccount!.bankName} · ${selectedAccount!.accountNumber}',
            variant: PillButtonVariant.secondary,
            onPressed: onChooseAccount,
          ),
          const SizedBox(height: 8),
          PillButton(
            key: const ValueKey('withdrawal-manage-accounts-link'),
            label: 'Manage payout accounts',
            variant: PillButtonVariant.text,
            fullWidth: false,
            onPressed: onManageAccounts,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const ValueKey('withdrawal-category-dropdown'),
            value: selectedCategory,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [
              for (final category in config.noteCategories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('withdrawal-note-field'),
            controller: noteController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 8),
          PillButton(
            key: const ValueKey('withdrawal-submit-button'),
            label: 'Request withdrawal',
            onPressed: submitting ? null : onSubmit,
          ),
          const SizedBox(height: 8),
          PillButton(
            key: const ValueKey('withdrawal-view-history-link'),
            label: 'View withdrawal history',
            variant: PillButtonVariant.text,
            fullWidth: false,
            onPressed: onViewHistory,
          ),
        ],
      ),
    );
  }
}
