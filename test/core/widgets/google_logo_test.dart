import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/widgets/google_logo.dart';

void main() {
  testWidgets('renders at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: GoogleLogo(size: 24))),
    );

    final box = tester.renderObject<RenderBox>(find.byType(GoogleLogo));
    expect(box.size, const Size(24, 24));
  });

  testWidgets('defaults to 18x18', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: GoogleLogo())),
    );

    final box = tester.renderObject<RenderBox>(find.byType(GoogleLogo));
    expect(box.size, const Size(18, 18));
  });
}
