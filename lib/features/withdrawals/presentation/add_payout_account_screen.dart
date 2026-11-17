import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../application/withdrawals_providers.dart';

const _accountTypes = ['BANK', 'MOBILE'];
const _accountTypeLabels = ['Bank', 'Mobile wallet'];

/// FR-701: add a payout account. `branch_name`/`routing_number` only make
/// sense for a bank account, so they're hidden (not just disabled) for
/// MOBILE -- the backend accepts them for either type, but a mobile wallet
/// (bKash/Nagad) genuinely has neither.
class AddPayoutAccountScreen extends ConsumerStatefulWidget {
  const AddPayoutAccountScreen({super.key});

  @override
  ConsumerState<AddPayoutAccountScreen> createState() =>
      _AddPayoutAccountScreenState();
}

class _AddPayoutAccountScreenState
    extends ConsumerState<AddPayoutAccountScreen> {
  int _typeIndex = 0;
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _routingNumberController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _branchNameController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  bool get _isBank => _accountTypes[_typeIndex] == 'BANK';

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final bankName = _bankNameController.text.trim();
    final holderName = _holderNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (bankName.length < 2) {
      _showError(_isBank
          ? 'Enter the bank name.'
          : 'Enter the mobile wallet provider (e.g. bKash).');
      return;
    }
    if (holderName.length < 2) {
      _showError('Enter the account holder name.');
      return;
    }
    if (accountNumber.length < 4) {
      _showError('Enter a valid account number.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(withdrawalsApiProvider).addAccount(
            accountType: _accountTypes[_typeIndex],
            bankName: bankName,
            holderName: holderName,
            accountNumber: accountNumber,
            branchName: _isBank && _branchNameController.text.trim().isNotEmpty
                ? _branchNameController.text.trim()
                : null,
            routingNumber:
                _isBank && _routingNumberController.text.trim().isNotEmpty
                    ? _routingNumberController.text.trim()
                    : null,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.message);
      return;
    }
    if (!mounted) return;
    ref.invalidate(payoutAccountsProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('add-payout-account-screen'),
      appBar: AppBar(title: const Text('Add payout account')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SegmentedPill(
              options: _accountTypeLabels,
              selectedIndex: _typeIndex,
              onChanged: (i) => setState(() => _typeIndex = i),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('payout-account-bank-name-field'),
              controller: _bankNameController,
              decoration: InputDecoration(
                  labelText: _isBank ? 'Bank name' : 'Mobile wallet provider'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('payout-account-holder-name-field'),
              controller: _holderNameController,
              decoration:
                  const InputDecoration(labelText: 'Account holder name'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('payout-account-number-field'),
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: 'Account number'),
            ),
            if (_isBank) ...[
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('payout-account-branch-name-field'),
                controller: _branchNameController,
                decoration:
                    const InputDecoration(labelText: 'Branch name (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('payout-account-routing-number-field'),
                controller: _routingNumberController,
                decoration: const InputDecoration(
                    labelText: 'Routing number (optional)'),
              ),
            ],
            const SizedBox(height: 24),
            PillButton(
              key: const ValueKey('payout-account-submit-button'),
              label: 'Save account',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
