import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/presentation/home_screen.dart';

const _countries = [
  Country(
    id: 107,
    iso2: 'JP',
    nameEn: 'Japan',
    isActive: true,
    slug: 'japan',
    flagUrl: 'https://flagcdn.com/w80/jp.png',
  ),
  Country(
      id: 18,
      iso2: 'BD',
      nameEn: 'Bangladesh',
      isActive: true,
      slug: 'bangladesh'),
];

Widget _app({
  AsyncValue<List<Country>> popular =
      const AsyncData<List<Country>>(_countries),
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/my-esims',
          builder: (context, state) => const Text('my-esims-placeholder')),
      GoRoute(
          path: '/wallet',
          builder: (context, state) => const Text('wallet-placeholder')),
    ],
  );

  return ProviderScope(
    overrides: [
      popularCountriesProvider.overrideWith((ref) {
        return switch (popular) {
          AsyncData(:final value) => Future.value(value),
          AsyncError(:final error) => Future<List<Country>>.error(error),
          _ => Completer<List<Country>>().future,
        };
      }),
      allCountriesProvider.overrideWith((ref) async => _countries),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows popular destinations from the provider', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Bangladesh'), findsOneWidget);
  });

  testWidgets(
      "there's no 'My eSIMs' or 'Top up' quick action in the hero -- both "
      'would just duplicate an existing bottom tab today', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('My eSIMs'), findsNothing);
    expect(find.text('Top up'), findsNothing);
    expect(find.text('Buy data'), findsOneWidget);
  });

  testWidgets('Buy data opens the FR-202 explore sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buy data'));
    await tester.pumpAndSettle();

    expect(find.text('Search countries'), findsOneWidget);
  });

  testWidgets('tapping the search pill also opens the explore sheet',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-search-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Search countries'), findsOneWidget);
  });

  testWidgets(
      "a popular-destination row tap still shows 'coming soon' (FR-204 doesn't exist yet)",
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Japan'));
    await tester.pump();

    expect(find.textContaining('coming soon'), findsOneWidget);
  });

  testWidgets('shows a retry error state when the provider throws',
      (tester) async {
    await tester
        .pumpWidget(_app(popular: AsyncError('boom', StackTrace.empty)));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load popular destinations."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while the provider resolves',
      (tester) async {
    await tester.pumpWidget(_app(popular: const AsyncLoading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
