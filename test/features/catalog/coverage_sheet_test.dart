import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/presentation/coverage_sheet.dart';

class _FakeCatalogApi implements CatalogApi {
  _FakeCatalogApi(this.coverage);
  final List<String> coverage;
  String? lastIso2;

  @override
  Future<List<Country>> getCountries({
    String? search,
    bool popularOnly = false,
  }) async =>
      const [];

  @override
  Future<List<String>> getCoverageCountries(String iso2) async {
    lastIso2 = iso2;
    return coverage;
  }

  @override
  Future<Destination> getDestination(String slug) => throw UnimplementedError();
}

Widget _app(_FakeCatalogApi fake) => ProviderScope(
      overrides: [catalogApiProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCoverageSheet(context,
                    iso2: 'AUKUS-3', name: 'AUKUS(3 countries)'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows the covered country names and a count', (tester) async {
    final fake =
        _FakeCatalogApi(const ['Australia', 'United Kingdom', 'United States']);
    await tester.pumpWidget(_app(fake));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(fake.lastIso2, 'AUKUS-3');
    expect(find.text('AUKUS(3 countries)'), findsOneWidget);
    expect(find.text('3 countries'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is no coverage data',
      (tester) async {
    final fake = _FakeCatalogApi(const []);
    await tester.pumpWidget(_app(fake));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No coverage details available.'), findsOneWidget);
  });

  testWidgets('tapping close dismisses the sheet', (tester) async {
    final fake = _FakeCatalogApi(const ['Australia']);
    await tester.pumpWidget(_app(fake));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Australia'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Australia'), findsNothing);
  });
}
