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
import '../../bootstrap/application/bootstrap_providers.dart';
import '../application/topup_launcher.dart';
import '../application/wallet_providers.dart';
import '../data/models/topup_checkout.dart';

/// FR-603: amount presets + custom entry, in the user's own currency, with
/// EUR limits from `/settings/public` shown converted for context (the
/// backend validates in EUR regardless of what currency the customer typed
/// in -- API.md §5). Presets are fixed EUR values (5/10/20/50) converted to
/// display/fill the field, since there's no backend-documented preset list.
class WalletTopupScreen extends ConsumerStatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  ConsumerState<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

const _presetEur = [Money(500), Money(1000), Money(2000), Money(5000)];

class _WalletTopupScreenState extends ConsumerState<WalletTopupScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(Money eurAmount, double rate) {
    final converted = eurAmount.eurValue * rate;
    _controller.text = converted.toStringAsFixed(2);
  }

  Future<void> _submit(String currency) async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }

    setState(() => _submitting = true);
    final TopupCheckout checkout;
    try {
      checkout = await ref
          .read(walletsApiProvider)
          .initiateTopup(amount: amount, currency: currency);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.mustChangePassword) {
        context.push('/set-password');
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    final launch = ref.read(walletTopupLauncherProvider);
    final failed = await launch(context, checkout.checkoutUrl);
    if (!mounted || failed == null) return;

    ref.invalidate(myWalletsProvider);
    ref.invalidate(ledgerProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failed ? 'Top-up failed.' : 'Top-up successful.')));
    if (!failed) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rateAsync = ref.watch(selectedCurrencyRateProvider);
    final codeAsync = ref.watch(currencyPreferenceProvider);
    final settingsAsync = ref.watch(bootstrapProvider);

    final rate = rateAsync.valueOrNull;
    final code = codeAsync.valueOrNull;
    final settings = settingsAsync.valueOrNull?.settings;
    final ready = rate != null && code != null && settings != null;
    final hasError =
        rateAsync.hasError || codeAsync.hasError || settingsAsync.hasError;

    String money(Money amount) => rate == null || code == null
        ? ''
        : formatMoney(amount, currencyCode: code, rateToBase: rate);

    void retry() {
      ref.invalidate(selectedCurrencyRateProvider);
      ref.invalidate(currencyPreferenceProvider);
      ref.invalidate(bootstrapProvider);
    }

    return TriptelScaffold(
      key: const ValueKey('wallet-topup-screen'),
      appBar: AppBar(title: const Text('Top up wallet')),
      body: hasError
          ? Center(
              child: ErrorState(
                message: "We couldn't load the top-up limits.",
                onRetry: retry,
              ),
            )
          : !ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Between ${money(settings.topupMin)} and '
                      '${money(settings.topupMax)}',
                      style: AppTypography.caption(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final preset in _presetEur)
                          _PresetChip(
                            key: ValueKey(
                                'wallet-topup-preset-${preset.eurCents}'),
                            label: money(preset),
                            onTap: () =>
                                setState(() => _applyPreset(preset, rate)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('wallet-topup-amount-field'),
                      controller: _controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Amount ($code)'),
                    ),
                    const SizedBox(height: 24),
                    PillButton(
                      key: const ValueKey('wallet-topup-submit-button'),
                      label: 'Top up',
                      onPressed: _submitting ? null : () => _submit(code),
                    ),
                  ],
                ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lilac100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child:
            Text(label, style: AppTypography.label(color: AppColors.primary)),
      ),
    );
  }
}
