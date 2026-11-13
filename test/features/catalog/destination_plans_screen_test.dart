import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/catalog/presentation/destination_plans_screen.dart';

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return ShareResult('', ShareResultStatus.success);
  }
}

const _country = Country(
  id: 107,
  iso2: 'JP',
  nameEn: 'Japan',
  isActive: true,
  slug: 'japan',
  flagUrl: 'https://flagcdn.com/w80/jp.png',
);

Product _fixed({required double gb, required int days, int cents = 200}) =>
    Product(
      id: 'fixed-$gb-$days',
      countryId: 107,
      titleEn: 'Japan ${gb}GB ${days}Days',
      dataAmountGb: gb,
      validityDays: days,
      retailPrice: Money(cents),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
    );

Product _unlimited(
        {required int days, int cents = 1000, bool featured = false}) =>
    Product(
      id: 'unlimited-$days-$cents',
      countryId: 107,
      titleEn: 'Japan Unlimited $days' 'Days',
      dataAmountGb: 0,
      validityDays: days,
      retailPrice: Money(cents),
      isUnlimited: true,
      isActive: true,
      isFeatured: featured,
    );

Widget _app(List<Product> products) => ProviderScope(
      overrides: [
        destinationProvider('japan').overrideWith(
          (ref) async => Destination(country: _country, products: products),
        ),
        selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
        currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      ],
      child: const MaterialApp(
        home: DestinationPlansScreen(slug: 'japan'),
      ),
    );

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

void main() {
  testWidgets(
      'shows the country name and only one plan-type tab when just '
      'one shape exists', (tester) async {
    await tester.pumpWidget(_app([_fixed(gb: 1, days: 7)]));
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsWidgets);
    expect(find.text('Data'), findsNothing); // no toggle with a single shape
    expect(find.text('1 GB'), findsOneWidget); // wheel label
    expect(find.textContaining('1 country'), findsOneWidget); // FR-204's
    // required "coverage" row fact
  });

  testWidgets('shows a plan-type toggle when multiple shapes exist',
      (tester) async {
    await tester
        .pumpWidget(_app([_fixed(gb: 1, days: 7), _unlimited(days: 3)]));
    await tester.pumpAndSettle();

    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Unlimited'), findsWidgets);
  });

  testWidgets('switching the wheel changes which plans are listed',
      (tester) async {
    await tester.pumpWidget(_app([
      _fixed(gb: 1, days: 7, cents: 200),
      _fixed(gb: 3, days: 7, cents: 500),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Japan 1.0GB 7Days'), findsOneWidget);
    expect(find.text('Japan 3.0GB 7Days'), findsNothing);
  });

  testWidgets('a featured plan shows the Recommended label', (tester) async {
    await tester.pumpWidget(_app([_unlimited(days: 3, featured: true)]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Recommended'), findsOneWidget);
  });

  testWidgets('tapping the share icon shares the public explore URL (FR-206)',
      (tester) async {
    final fakePlatform = _FakeSharePlatform();
    SharePlatform.instance = fakePlatform;
    addTearDown(() => SharePlatform.instance = SharePlatform());

    await tester.pumpWidget(_app([_fixed(gb: 1, days: 7)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('share-destination-button')));
    await tester.pumpAndSettle();

    expect(fakePlatform.lastParams?.text, 'https://triptel.co/explore/japan');
    expect(fakePlatform.lastParams?.subject, 'Japan');
  });

  testWidgets('tapping "Plan details" opens FR-205\'s detail sheet',
      (tester) async {
    await tester.pumpWidget(_app([_fixed(gb: 1, days: 7)]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan details'));
    await tester.pumpAndSettle();

    expect(find.text('Japan · 1 country'), findsOneWidget);
  });

  testWidgets(
      'selecting a plan then tapping Continue shows "coming soon" '
      '(checkout, FR-301+, does not exist yet)', (tester) async {
    await tester.pumpWidget(_app([_fixed(gb: 1, days: 7)]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Japan 1.0GB 7Days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.textContaining('coming soon'), findsOneWidget);
  });

  testWidgets(
      'shows an error state with retry when the destination fails to load',
      (tester) async {
    final container = ProviderContainer(overrides: [
      destinationProvider('japan')
          .overrideWith((ref) async => throw Exception('boom')),
      selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
      currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DestinationPlansScreen(slug: 'japan'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this destination."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
