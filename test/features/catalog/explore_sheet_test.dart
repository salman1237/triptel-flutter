import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/presentation/explore_sheet.dart';

const _japan = Country(
  id: 107,
  iso2: 'JP',
  nameEn: 'Japan',
  isActive: true,
  slug: 'japan',
  isPopular: true,
);
const _bangladesh = Country(
    id: 18,
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

class _FakeCatalogApi implements CatalogApi {
  _FakeCatalogApi(this.all);
  final List<Country> all;
  String? lastSearch;

  @override
  Future<List<Country>> getCountries({
    String? search,
    bool popularOnly = false,
  }) async {
    lastSearch = search;
    if (search != null && search.isNotEmpty) {
      return all
          .where((c) => c.nameEn.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return all;
  }

  @override
  Future<List<String>> getCoverageCountries(String iso2) async =>
      const ['Australia', 'United Kingdom', 'United States'];
}

Widget _app({List<Country>? all}) {
  final fake = _FakeCatalogApi(all ?? const [_japan, _bangladesh, _regional]);
  return ProviderScope(
    overrides: [catalogApiProvider.overrideWithValue(fake)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showExploreSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the Country tab by default with popular chips',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsWidgets);
    expect(find.text('Bangladesh'), findsOneWidget);
    expect(find.text('AUKUS(3 countries)'), findsNothing);
    expect(find.text('Popular'), findsOneWidget);
  });

  testWidgets('switching to the Regional tab shows only regional entries',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regional'));
    await tester.pumpAndSettle();

    expect(find.text('AUKUS(3 countries)'), findsOneWidget);
    expect(find.text('Bangladesh'), findsNothing);
  });

  testWidgets(
      'a regional row shows a real "N countries" subtitle (FR-203), not '
      'just the raw package name', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regional'));
    await tester.pumpAndSettle();

    expect(find.text('AUKUS(3 countries)'), findsOneWidget);
    expect(find.text('3 countries'), findsOneWidget);
  });

  testWidgets('typing a search query debounces then calls the API',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('explore-search')).first, 'japan');
    // Before the debounce elapses, nothing has resolved yet.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Bangladesh'), findsNothing);
  });

  testWidgets('a search matching nothing shows an empty state', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('explore-search')).first, 'zzz-nonexistent');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('No destinations match'), findsOneWidget);
  });

  testWidgets('tapping the close icon dismisses the sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Bangladesh'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Bangladesh'), findsNothing);
  });

  testWidgets(
      'tapping a regional entry opens its coverage sheet (FR-203), not a '
      "coming-soon snack", (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AUKUS(3 countries)'));
    await tester.pumpAndSettle();

    expect(find.text('3 countries'), findsWidgets);
    expect(find.text('Australia'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsNothing);
  });

  testWidgets('tapping a non-regional entry still shows "coming soon"',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bangladesh'));
    await tester.pump();

    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}
