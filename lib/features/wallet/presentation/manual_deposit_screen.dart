import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/absolute_url.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../../bootstrap/data/models/payment_method.dart';
import '../application/wallet_providers.dart';

/// FR-604: choose a configured manual-deposit method (bKash/bank/etc. from
/// `/settings/public.payment_methods`), show its account details +
/// instructions + the shared Bangla QR image, then submit amount (fixed to
/// BDT -- every configured method here is a Bangladesh domestic transfer
/// method, so a currency picker would be a choice with no real use, same
/// judgement as other narrow-scope screens this session) + transaction ID.
/// No endpoint lists past deposits (API.md §5) -- the result IS the
/// "pending admin approval" message, nothing more.
class ManualDepositScreen extends ConsumerStatefulWidget {
  const ManualDepositScreen({super.key});

  @override
  ConsumerState<ManualDepositScreen> createState() =>
      _ManualDepositScreenState();
}

class _ManualDepositScreenState extends ConsumerState<ManualDepositScreen> {
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  PaymentMethod? _selectedMethod;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _chooseMethod(List<PaymentMethod> methods) async {
    final id = await PaymentMethodSheet.show(
      context,
      [
        for (final m in methods)
          PaymentMethodOption(
            id: m.id,
            label: m.name,
            subtitle: m.accountNumber,
            icon: Icons.account_balance,
          ),
      ],
    );
    if (id == null) return;
    setState(() => _selectedMethod = methods.firstWhere((m) => m.id == id));
  }

  Future<void> _submit() async {
    final method = _selectedMethod;
    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a payment method first.')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }
    final transactionId = _transactionIdController.text.trim();
    if (transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter the transaction ID from your receipt.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(walletsApiProvider).submitManualDeposit(
            amount: amount,
            currency: 'BDT',
            bankName: method.name,
            transactionId: transactionId,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(bootstrapProvider);

    return TriptelScaffold(
      key: const ValueKey('manual-deposit-screen'),
      appBar: AppBar(title: const Text('Manual deposit')),
      body: switch (settingsAsync) {
        AsyncData(:final value) => _submitted
            ? const _SubmittedResult()
            : _Form(
                methods: value.settings.paymentMethods,
                banglaQrImage: value.settings.banglaQrImage,
                selectedMethod: _selectedMethod,
                amountController: _amountController,
                transactionIdController: _transactionIdController,
                submitting: _submitting,
                onChooseMethod: () =>
                    _chooseMethod(value.settings.paymentMethods),
                onSubmit: _submit,
              ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load the deposit methods.",
              onRetry: () => ref.invalidate(bootstrapProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.methods,
    required this.banglaQrImage,
    required this.selectedMethod,
    required this.amountController,
    required this.transactionIdController,
    required this.submitting,
    required this.onChooseMethod,
    required this.onSubmit,
  });

  final List<PaymentMethod> methods;
  final String? banglaQrImage;
  final PaymentMethod? selectedMethod;
  final TextEditingController amountController;
  final TextEditingController transactionIdController;
  final bool submitting;
  final VoidCallback onChooseMethod;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.account_balance_outlined,
          message: 'No manual deposit methods are configured right now.',
        ),
      );
    }

    final method = selectedMethod;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey('manual-deposit-choose-method-button'),
            label: method == null ? 'Choose payment method' : method.name,
            variant: PillButtonVariant.secondary,
            onPressed: onChooseMethod,
          ),
          if (method != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [appCardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (method.accountName != null)
                    _InfoRow(label: 'Account name', value: method.accountName!),
                  if (method.accountNumber != null)
                    _InfoRow(
                        label: 'Account number', value: method.accountNumber!),
                  if (method.branch != null)
                    _InfoRow(label: 'Branch', value: method.branch!),
                  if (method.instructions != null)
                    _InfoRow(
                        label: 'Instructions', value: method.instructions!),
                ],
              ),
            ),
            if (banglaQrImage != null) ...[
              const SizedBox(height: 16),
              Center(
                child: CachedNetworkImage(
                  key: const ValueKey('manual-deposit-bangla-qr'),
                  imageUrl: resolveApiUrl(banglaQrImage!),
                  width: 180,
                  height: 180,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('manual-deposit-amount-field'),
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (BDT)'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('manual-deposit-transaction-id-field'),
            controller: transactionIdController,
            decoration: const InputDecoration(labelText: 'Transaction ID'),
          ),
          const SizedBox(height: 24),
          PillButton(
            key: const ValueKey('manual-deposit-submit-button'),
            label: 'Submit',
            onPressed: submitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption(color: AppColors.inkMuted)),
          Text(value, style: AppTypography.body()),
        ],
      ),
    );
  }
}

class _SubmittedResult extends StatelessWidget {
  const _SubmittedResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('manual-deposit-result'),
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.primary, size: 40),
            const SizedBox(height: 16),
            Text(
              'Submitted. Your deposit is pending admin approval.',
              textAlign: TextAlign.center,
              style: AppTypography.body(),
            ),
          ],
        ),
      ),
    );
  }
}
