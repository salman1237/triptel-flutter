import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'currency_format.dart';
import 'currency_providers.dart';

/// FR-005's header pill (Eskimo's "USD $" pill): shows the selected currency
/// code, opens a bottom sheet to switch it. Design_System.md §3: bottom
/// sheets for choices.
class CurrencyPillSwitcher extends ConsumerWidget {
  const CurrencyPillSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyPreferenceProvider);

    return currency.when(
      loading: () => const SizedBox(width: 64, height: 32),
      error: (error, stack) => const SizedBox.shrink(),
      data: (code) => GestureDetector(
        key: const ValueKey('currency-pill'),
        onTap: () => _openSheet(context, ref, code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$code ${currencySymbol(code)}',
                style: AppTypography.label(color: AppColors.ink),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, String selectedCode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final options = sheetRef.watch(availableCurrenciesProvider);
          return SafeArea(
            child: options.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
              data: (rates) => ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Choose currency',
                        style: AppTypography.headline()),
                  ),
                  for (final rate in rates)
                    ListTile(
                      key: ValueKey('currency-option-${rate.currencyCode}'),
                      title: Text(
                        '${rate.currencyCode} ${currencySymbol(rate.currencyCode)}',
                        style: AppTypography.body(),
                      ),
                      trailing: rate.currencyCode == selectedCode
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        sheetRef
                            .read(currencyPreferenceProvider.notifier)
                            .select(rate.currencyCode);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
