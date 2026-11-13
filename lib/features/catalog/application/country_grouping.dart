import '../data/models/country.dart';

/// FR-202's Country/Regional split and A-Z sectioning, kept pure/testable
/// (Architecture.md: business rules in plain Dart). Country tab = `region !=
/// "Regional"`; Regional tab = `region == "Regional"` (API.md §3 -- maps 1:1
/// to Eskimo's Country/Regional toggle).
List<Country> countryTabEntries(List<Country> all) =>
    all.where((c) => !c.isRegional).toList();

List<Country> regionalTabEntries(List<Country> all) =>
    all.where((c) => c.isRegional).toList();

/// Groups [countries] by the first letter of `nameEn`, A-Z, each group
/// itself sorted alphabetically.
Map<String, List<Country>> groupByFirstLetter(List<Country> countries) {
  final sorted = [...countries]
    ..sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
  final groups = <String, List<Country>>{};
  for (final country in sorted) {
    final letter =
        country.nameEn.isNotEmpty ? country.nameEn[0].toUpperCase() : '#';
    (groups[letter] ??= []).add(country);
  }
  return groups;
}
