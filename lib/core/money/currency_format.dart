import 'money.dart';

/// Display symbols for the beta currencies (API.md §1): AED, INR, JPY, MYR,
/// SAR, SGD, THB, USD, BDT, EUR, GBP. Unlisted codes fall back to the code.
const _symbols = {
  'EUR': '€',
  'USD': '\$',
  'GBP': '£',
  'BDT': '৳',
  'INR': '₹',
  'JPY': '¥',
  'THB': '฿',
  'SGD': 'S\$',
  'MYR': 'RM',
  'AED': 'د.إ',
  'SAR': 'ر.س',
};

/// JPY has no minor unit; every other beta currency uses 2 decimals.
const _zeroDecimalCurrencies = {'JPY'};

String currencySymbol(String currencyCode) =>
    _symbols[currencyCode] ?? currencyCode;

/// Converts [amount] (EUR) to [currencyCode] using [rateToBase] (units per 1
/// EUR, API.md §1) and formats it with the currency's symbol. Display-only —
/// the converted value is never stored as truth (Rules.md).
String formatMoney(Money amount,
    {required String currencyCode, required double rateToBase}) {
  final converted = amount.eurValue * rateToBase;
  final decimals = _zeroDecimalCurrencies.contains(currencyCode) ? 0 : 2;
  return '${currencySymbol(currencyCode)}${converted.toStringAsFixed(decimals)}';
}
