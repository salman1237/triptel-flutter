import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/features/guides/application/esim_setup_guide_content.dart';
import 'package:triptel/features/guides/presentation/esim_setup_guide_screen.dart';

Widget _app() {
  final router = GoRouter(initialLocation: '/guide', routes: [
    GoRoute(
      path: '/guide',
      builder: (context, state) => const EsimSetupGuideScreen(),
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
  testWidgets(
      'shows the install-once warning and every real iOS/Android '
      'step', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('can only be installed once'), findsOneWidget);
    for (final step in iosSetupSteps) {
      expect(find.text(step), findsOneWidget);
    }
    for (final step in androidSetupSteps) {
      expect(find.text(step), findsOneWidget);
    }
  });

  testWidgets('shows every real troubleshooting item', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final item in setupGuideTroubleshooting) {
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets('tapping "Check device compatibility" navigates to FR-952',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
        find.byKey(const ValueKey('esim-setup-guide-compatibility-link')));
    await tester
        .tap(find.byKey(const ValueKey('esim-setup-guide-compatibility-link')));
    await tester.pumpAndSettle();

    expect(find.text('devices-placeholder'), findsOneWidget);
  });
}
