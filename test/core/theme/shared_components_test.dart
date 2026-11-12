import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/app/theme_preview_screen.dart';
import 'package:triptel/core/theme/theme.dart';
import 'package:triptel/core/widgets/widgets.dart';

void main() {
  Future<void> pumpPreview(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const ThemePreviewScreen()),
      );

  testWidgets(
      'FR-001 preview renders every Design_System.md §4 shared component', (
    tester,
  ) async {
    await pumpPreview(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('fr-001-preview')), findsOneWidget);
    expect(find.byType(TriptelScaffold), findsOneWidget);
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.byType(SearchPill), findsOneWidget);
    expect(find.byType(SegmentedPill), findsOneWidget);
    expect(find.byType(CountryRow), findsOneWidget);
    expect(find.byType(FlagAvatar), findsOneWidget);
    expect(find.byType(BalanceCard), findsOneWidget);
    expect(find.byType(ListGroup), findsOneWidget);
    expect(find.byType(ListRow), findsNWidgets(2));
    expect(find.byType(InfoBox), findsOneWidget);
    expect(find.byType(StatusChip), findsNWidgets(3));
    expect(find.byType(PlanOptionTile), findsOneWidget);
    expect(find.byType(PriceText), findsOneWidget);
    expect(find.byType(UsageRing), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(StickyTotalBar), findsOneWidget);
    expect(find.byType(PillButton), findsWidgets);
  });

  testWidgets('SegmentedPill reports taps via onChanged', (tester) async {
    await pumpPreview(tester);
    await tester.pump();

    await tester.tap(find.text('Regional'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Regional'), findsOneWidget);
  });
}
