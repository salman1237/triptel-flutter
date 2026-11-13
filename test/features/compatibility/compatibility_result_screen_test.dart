import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/compatibility/presentation/compatibility_result_screen.dart';

Widget _app(AsyncValue<EsimVerdict> verdict) => ProviderScope(
      overrides: [
        esimVerdictProvider.overrideWith((ref) {
          return switch (verdict) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future<EsimVerdict>.error(error),
            _ => Completer<EsimVerdict>().future,
          };
        }),
      ],
      child: const MaterialApp(home: CompatibilityResultScreen()),
    );

void main() {
  testWidgets('supported shows the green headline and device chip',
      (tester) async {
    await tester.pumpWidget(_app(const AsyncData(EsimVerdict(
      kind: EsimVerdictKind.supported,
      deviceLabel: 'vivo V2344',
      reason: 'eSIM is supported and enabled on this device.',
    ))));
    await tester.pumpAndSettle();

    expect(find.text('Your device supports eSIM'), findsOneWidget);
    expect(find.text('vivo V2344'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('notSupported shows the red headline', (tester) async {
    await tester.pumpWidget(_app(const AsyncData(EsimVerdict(
      kind: EsimVerdictKind.notSupported,
      deviceLabel: 'vivo V2344',
      reason: 'This device has no eSIM hardware.',
    ))));
    await tester.pumpAndSettle();

    expect(find.text('Your device does not support eSIM'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('unknown shows the amber headline, not a notSupported one',
      (tester) async {
    await tester.pumpWidget(_app(const AsyncData(EsimVerdict(
      kind: EsimVerdictKind.unknown,
      deviceLabel: 'vivo V2344',
      reason: 'Android version too old to check eSIM support.',
    ))));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't confirm eSIM support"), findsOneWidget);
    expect(find.text('Your device does not support eSIM'), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets('shows a loading indicator while the verdict resolves',
      (tester) async {
    await tester.pumpWidget(_app(const AsyncLoading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a retry error state when the channel throws',
      (tester) async {
    await tester.pumpWidget(_app(AsyncError('boom', StackTrace.empty)));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't check this device's eSIM support."),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
