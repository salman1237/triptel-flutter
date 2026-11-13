import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/data/models/country.dart';

void main() {
  test('Country.fromJson parses the real beta fixture', () {
    final raw =
        File('test/fixtures/catalog_popular_countries.json').readAsStringSync();
    final json = jsonDecode(raw) as List;

    final countries =
        json.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();

    expect(countries, hasLength(11));
    final japan = countries.firstWhere((c) => c.iso2 == 'JP');
    expect(japan.nameEn, 'Japan');
    expect(japan.slug, 'japan');
    expect(japan.flagUrl, 'https://flagcdn.com/w80/jp.png');
    expect(japan.isPopular, true);
    expect(japan.isRegional, false);
  });

  test('isRegional is true only when region == "Regional"', () {
    const regional = Country(
      id: 1,
      iso2: 'AUKUS-3',
      nameEn: 'AUKUS(3 countries)',
      isActive: true,
      slug: 'aukus-3-countries',
      region: 'Regional',
    );
    const country = Country(
      id: 2,
      iso2: 'JP',
      nameEn: 'Japan',
      isActive: true,
      slug: 'japan',
    );

    expect(regional.isRegional, true);
    expect(country.isRegional, false);
  });

  test('missing optional fields fall back safely', () {
    final country = Country.fromJson(const {
      'id': 1,
      'iso2': 'JP',
      'name_en': 'Japan',
      'slug': 'japan',
    });

    expect(country.flagUrl, isNull);
    expect(country.isPopular, false);
    expect(country.popularOrder, 0);
    expect(country.isActive, true);
  });
}
