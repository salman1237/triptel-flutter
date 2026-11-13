import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/presentation/supported_devices_screen.dart';

void main() {
  testWidgets('shows Apple models by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('iPhone 15'), findsOneWidget);
    expect(find.textContaining('Pixel'), findsNothing);
  });

  testWidgets('switching the brand chip shows that brand\'s models',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Samsung'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Galaxy S25'), findsOneWidget);
    expect(find.textContaining('iPhone 15'), findsNothing);
  });

  testWidgets('typing a search query filters the list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    // "2020" only appears in the SE model, so this also proves the match
    // isn't just the first/most-visible item in the (lazily built) list.
    await tester.enterText(find.byType(TextField), '2020');
    await tester.pumpAndSettle();

    expect(find.textContaining('iPhone SE'), findsOneWidget);
    expect(find.textContaining('iPhone 15'), findsNothing);
  });

  testWidgets('a query matching nothing shows an empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz-nonexistent');
    await tester.pumpAndSettle();

    expect(find.textContaining('No Apple models match'), findsOneWidget);
  });

  testWidgets('shows the EID dial tip and settings fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('*#06#'), findsWidgets);
    expect(find.textContaining('Digital SIM'), findsOneWidget);
  });

  testWidgets('the brand chip row does not overflow on a narrow phone width',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SupportedDevicesScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
