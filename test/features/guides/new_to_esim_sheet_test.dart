import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/guides/presentation/new_to_esim_sheet.dart';

Widget _app() {
  final router = GoRouter(initialLocation: '/home', routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showNewToEsimSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/guides/esim-setup-guide',
      builder: (context, state) =>
          const Scaffold(body: Text('setup-guide-placeholder')),
    ),
    GoRoute(
      path: '/compatibility/devices',
      builder: (context, state) =>
          const Scaffold(body: Text('devices-placeholder')),
    ),
  ]);
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('shows the explainer and both link buttons', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('New to eSIM?'), findsOneWidget);
    expect(find.textContaining('no physical card'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('new-to-esim-guide-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-to-esim-compatibility-button')),
        findsOneWidget);
  });

  testWidgets(
      'tapping "View setup guide" closes the sheet and navigates '
      'to FR-901', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('new-to-esim-guide-button')));
    await tester.pumpAndSettle();

    expect(find.text('setup-guide-placeholder'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-to-esim-sheet')), findsNothing);
  });

  testWidgets(
      'tapping "Check device compatibility" closes the sheet and '
      'navigates to FR-952', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('new-to-esim-compatibility-button')));
    await tester.pumpAndSettle();

    expect(find.text('devices-placeholder'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-to-esim-sheet')), findsNothing);
  });

  testWidgets('tapping close dismisses the sheet without navigating',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-to-esim-sheet')), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
