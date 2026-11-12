import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/bootstrap/application/bootstrap_providers.dart';
import '../../features/bootstrap/data/models/currency_rate.dart';
import '../storage/shared_prefs_provider.dart';
import 'currency_preference.dart';

const _prefsKey = 'currency.selected';

class CurrencyPreferenceNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final bootstrap = await ref.watch(bootstrapProvider.future);
    final available = <String>{
      bootstrap.settings.defaultCurrency,
      ...bootstrap.rates.map((r) => r.currencyCode),
    }.toList();
    return resolveInitialCurrency(
      storedCode: prefs.getString(_prefsKey),
      defaultCurrency: bootstrap.settings.defaultCurrency,
      availableCodes: available,
    );
  }

  /// Persists locally. Once auth (FR-101..109) exists, also sync via
  /// `PUT /auth/me/preferences` when signed in (FR-005) — tracked as a
  /// follow-up, not blocking this feature per CLAUDE.md's autonomous loop.
  Future<void> select(String currencyCode) async {
    state = AsyncData(currencyCode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_prefsKey, currencyCode);
  }
}

final currencyPreferenceProvider =
    AsyncNotifierProvider<CurrencyPreferenceNotifier, String>(
  CurrencyPreferenceNotifier.new,
);

/// The rate (units per 1 EUR) for the currently selected currency; 1.0 for EUR.
final selectedCurrencyRateProvider = FutureProvider<double>((ref) async {
  final code = await ref.watch(currencyPreferenceProvider.future);
  final bootstrap = await ref.watch(bootstrapProvider.future);
  return resolveRate(code, bootstrap.rates);
});

/// Every currency the backend currently offers rates for, plus EUR itself.
final availableCurrenciesProvider =
    FutureProvider<List<CurrencyRate>>((ref) async {
  final bootstrap = await ref.watch(bootstrapProvider.future);
  final hasEur = bootstrap.rates.any((r) => r.currencyCode == 'EUR');
  return [
    if (!hasEur) const CurrencyRate(currencyCode: 'EUR', rateToBase: 1),
    ...bootstrap.rates,
  ];
});
