import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:triptel/main.dart';

void main() {
  testWidgets('TriptelApp renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TriptelApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
