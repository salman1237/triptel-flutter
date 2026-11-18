import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/data/models/featured_package.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
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
  _FakeCatalogApi(this.all, {this.featured = const []});
  final List<Country> all;
  final List<FeaturedPackage> featured;
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
  Future<List<FeaturedPackage>> getFeaturedPackages() async => featured;

  @override
  Future<List<String>> getCoverageCountries(String iso2) async =>
      const ['Australia', 'United Kingdom', 'United States'];

  @override
  Future<Destination> getDestination(String slug) => throw UnimplementedError();

  @override
  Future<Product> getProduct(String productId) => throw UnimplementedError();
}

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

const _globalPackage = FeaturedPackage(
  productId: 'd291e871-d86b-47bb-b372-e8bef1eb8ed7',
  title: 'Global139 10GB 30Days',
  retailPrice: Money(11172),
  dataAmountGb: 10,
  validityDays: 30,
  isUnlimited: false,
  countryCount: 127,
  countryIso2: 'GL-139',
  countryName: 'Global139',
  countrySlug: 'global139',
  flagUrl: null,
);

Widget _app({List<Country>? all, List<FeaturedPackage> featured = const []}) {
  final fake = _FakeCatalogApi(
    all ?? const [_japan, _bangladesh, _regional],
    featured: featured,
  );
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showExploreSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/explore/:slug',
        builder: (context, state) =>
            Text('plans-placeholder-${state.pathParameters['slug']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      catalogApiProvider.overrideWithValue(fake),
      selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
      currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
    ],
    child: MaterialApp.router(routerConfig: router),
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
      'tapping a regional entry\'s row (not its "N countries" subtitle) '
      "closes the sheet and navigates to FR-204's plans screen -- a "
      'regional package is a real, purchasable product, not a dead end',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AUKUS(3 countries)'));
    await tester.pumpAndSettle();

    expect(find.text('plans-placeholder-aukus-3-countries'), findsOneWidget);
    expect(find.text('3 countries'), findsNothing);
  });

  testWidgets(
      'tapping a regional entry\'s "N countries" subtitle opens its '
      'coverage sheet (FR-203) instead of navigating away', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 countries'));
    await tester.pumpAndSettle();

    expect(find.text('Australia'), findsOneWidget);
    expect(find.text('plans-placeholder-aukus-3-countries'), findsNothing);
  });

  testWidgets(
      'tapping a non-regional entry closes the sheet and navigates to '
      "FR-204's plans screen", (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bangladesh'));
    await tester.pumpAndSettle();

    expect(find.text('plans-placeholder-bangladesh'), findsOneWidget);
  });

  testWidgets(
      'FR-202b: the real featured "Global" card shows its real price, '
      'data/validity, and country count', (tester) async {
    await tester.pumpWidget(_app(featured: const [_globalPackage]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('explore-featured-package')), findsOneWidget);
    expect(find.text('Global139 10GB 30Days'), findsOneWidget);
    expect(find.textContaining('10 GB'), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);
    expect(find.textContaining('127 countries'), findsOneWidget);
    expect(find.textContaining('111.72'), findsOneWidget);
  });

  testWidgets(
      'an empty featured list (nothing currently highlighted) hides the '
      'card without an error -- API.md documents this as normal',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('explore-featured-package')), findsNothing);
  });

  testWidgets(
      'a featured product with no coverage list omits the country-count '
      'line instead of showing "0 countries"', (tester) async {
    const noCoverage = FeaturedPackage(
      productId: 'p-1',
      title: 'Global',
      retailPrice: Money(500),
      dataAmountGb: 1,
      validityDays: 7,
      isUnlimited: false,
      countryCount: null,
      countryIso2: 'GL',
      countryName: 'Global',
      countrySlug: 'global',
      flagUrl: null,
    );
    await tester.pumpWidget(_app(featured: const [noCoverage]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('explore-featured-package'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.textContaining('countries')),
      findsNothing,
    );
  });

  testWidgets(
      'tapping the featured card closes the sheet and navigates to its '
      'real country', (tester) async {
    await tester.pumpWidget(_app(featured: const [_globalPackage]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('explore-featured-package')));
    await tester.pumpAndSettle();

    expect(find.text('plans-placeholder-global139'), findsOneWidget);
  });

  testWidgets('the featured card is hidden while actively searching',
      (tester) async {
    await tester.pumpWidget(_app(featured: const [_globalPackage]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('explore-search')).first, 'japan');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('explore-featured-package')), findsNothing);
  });
}
