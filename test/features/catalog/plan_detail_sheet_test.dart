import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/catalog/presentation/plan_detail_sheet.dart';

Product _fixed() => const Product(
      id: 'f',
      countryId: 107,
      titleEn: 'Japan 1GB 7Days (IIJ)',
      dataAmountGb: 1,
      validityDays: 7,
      retailPrice: Money(100),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
    );

Product _regional() => const Product(
      id: 'r',
      countryId: 272,
      titleEn: 'AUKUS 1GB 30Days',
      dataAmountGb: 1,
      validityDays: 30,
      retailPrice: Money(500),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
      coverageCountries: ['Australia', 'United Kingdom', 'United States'],
    );

Widget _app(Product product, String countryName) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showPlanDetailSheet(context,
                  product: product, countryName: countryName),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows the full disambiguating title and plan facts',
      (tester) async {
    await tester.pumpWidget(_app(_fixed(), 'Japan'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Japan 1GB 7Days (IIJ)'), findsOneWidget);
    expect(find.text('Fixed data'), findsOneWidget);
    expect(find.text('Starts on install'), findsOneWidget);
    expect(find.text('Personal hotspot'), findsOneWidget);
  });

  testWidgets(
      'a single-country product shows "1 country" with the destination name',
      (tester) async {
    await tester.pumpWidget(_app(_fixed(), 'Japan'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Japan · 1 country'), findsOneWidget);
  });

  testWidgets(
      'a regional product (coverage_countries set) lists the real covered '
      'countries instead', (tester) async {
    await tester.pumpWidget(_app(_regional(), 'AUKUS(3 countries)'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('3 countries'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.textContaining('· 1 country'), findsNothing);
  });

  testWidgets('tapping close dismisses the sheet', (tester) async {
    await tester.pumpWidget(_app(_fixed(), 'Japan'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Fixed data'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Fixed data'), findsNothing);
  });
}
