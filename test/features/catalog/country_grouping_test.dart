import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/country_grouping.dart';
import 'package:triptel/features/catalog/data/models/country.dart';

const _japan =
    Country(id: 1, iso2: 'JP', nameEn: 'Japan', isActive: true, slug: 'japan');
const _bangladesh = Country(
    id: 2,
    iso2: 'BD',
    nameEn: 'Bangladesh',
    isActive: true,
    slug: 'bangladesh');
const _regional = Country(
  id: 3,
  iso2: 'AUKUS-3',
  nameEn: 'AUKUS(3 countries)',
  isActive: true,
  slug: 'aukus-3-countries',
  region: 'Regional',
);

void main() {
  group('countryTabEntries / regionalTabEntries', () {
    test('splits by region == "Regional"', () {
      final all = [_japan, _bangladesh, _regional];

      expect(countryTabEntries(all), [_japan, _bangladesh]);
      expect(regionalTabEntries(all), [_regional]);
    });

    test('an empty list produces empty results for both tabs', () {
      expect(countryTabEntries(const []), isEmpty);
      expect(regionalTabEntries(const []), isEmpty);
    });
  });

  group('groupByFirstLetter', () {
    test('groups and sorts alphabetically, case-insensitive', () {
      final groups = groupByFirstLetter([_japan, _bangladesh]);

      expect(groups.keys.toList(), ['B', 'J']);
      expect(groups['B'], [_bangladesh]);
      expect(groups['J'], [_japan]);
    });

    test('multiple countries sharing a letter are sorted within the group', () {
      const belgium = Country(
          id: 4,
          iso2: 'BE',
          nameEn: 'Belgium',
          isActive: true,
          slug: 'belgium');
      final groups = groupByFirstLetter([_bangladesh, belgium]);

      expect(groups['B'], [_bangladesh, belgium]);
    });
  });
}
