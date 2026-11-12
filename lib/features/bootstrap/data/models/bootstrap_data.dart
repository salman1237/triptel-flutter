import 'currency_rate.dart';
import 'language.dart';
import 'public_settings.dart';

/// Combined result of the bootstrap calls, with provenance for FR-002's
/// "cache for offline start" behaviour.
class BootstrapData {
  const BootstrapData({
    required this.settings,
    required this.rates,
    required this.languages,
    required this.fromCache,
  });

  final PublicSettings settings;
  final List<CurrencyRate> rates;
  final List<Language> languages;
  final bool fromCache;

  BootstrapData copyWith({bool? fromCache}) => BootstrapData(
        settings: settings,
        rates: rates,
        languages: languages,
        fromCache: fromCache ?? this.fromCache,
      );
}
