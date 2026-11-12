import '../../features/bootstrap/data/models/currency_rate.dart';

/// FR-005's pure selection rule, kept out of the Riverpod notifier so it's
/// unit-testable without a provider container (Architecture.md). A stored
/// choice wins only if it's still one of the currencies the backend offers;
/// otherwise fall back to the platform default.
String resolveInitialCurrency({
  required String? storedCode,
  required String defaultCurrency,
  required List<String> availableCodes,
}) {
  if (storedCode != null && availableCodes.contains(storedCode)) {
    return storedCode;
  }
  return defaultCurrency;
}

/// The rate (units per 1 EUR) for [currencyCode] among [rates]; 1.0 for EUR
/// or any currency the backend hasn't published a rate for.
double resolveRate(String currencyCode, List<CurrencyRate> rates) {
  if (currencyCode == 'EUR') return 1.0;
  final match = rates.where((r) => r.currencyCode == currencyCode);
  return match.isEmpty ? 1.0 : match.first.effectiveRate;
}
