import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:triptel/core/theme/tokens.dart';
import 'package:triptel/core/widgets/esim_qr.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// FR-401/Rules.md: the logo disc must stay small enough that QR error
/// correction level H (which recovers roughly up to 30% codeword loss)
/// can still decode the code despite the logo obscuring its centre. There's
/// no QR decoder dependency in this project, so this proves the geometric
/// margin directly: the disc's area as a fraction of the whole QR, which is
/// what actually determines how much of the code is obscured.
double _discAreaFraction(double size) {
  final logoSize = size * EsimQr.logoFraction;
  final discDiameter = logoSize + 8;
  final discRadius = discDiameter / 2;
  final discArea = math.pi * discRadius * discRadius;
  final qrArea = size * size;
  return discArea / qrArea;
}

void main() {
  group('EsimQr (FR-401)', () {
    testWidgets('uses error correction level H', (tester) async {
      await tester
          .pumpWidget(_wrap(const EsimQr(data: 'LPA:1\$smdp.example\$CODE')));

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
    });

    testWidgets('renders the app mark on a white circular disc',
        (tester) async {
      await tester.pumpWidget(_wrap(EsimQr(
        data: 'LPA:1\$smdp.example\$CODE',
        logo: Container(key: const ValueKey('app-mark')),
      )));

      expect(find.byKey(const ValueKey('app-mark')), findsOneWidget);
      final disc = tester.widget<Container>(find
          .ancestor(
            of: find.byKey(const ValueKey('app-mark')),
            matching: find.byType(Container),
          )
          .first);
      final decoration = disc.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, AppColors.surface);
    });

    testWidgets('no logo renders no disc at all', (tester) async {
      await tester
          .pumpWidget(_wrap(const EsimQr(data: 'LPA:1\$smdp.example\$CODE')));

      expect(find.byType(QrImageView), findsOneWidget);
      // Only the outer SizedBox/Stack -- no extra circular Container.
      final circles = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              (c.decoration as BoxDecoration?)?.shape == BoxShape.circle);
      expect(circles, isEmpty);
    });

    test(
        'the logo disc stays well inside EC level H\'s ~30% damage-recovery '
        'margin, at every size this app actually uses', () {
      for (final size in [160.0, 220.0, 320.0]) {
        final fraction = _discAreaFraction(size);
        expect(fraction, lessThan(0.15),
            reason: 'disc covers ${(fraction * 100).toStringAsFixed(1)}% '
                'of the QR at size $size -- must stay comfortably under '
                "EC level H's ~30% recoverable damage");
      }
    });

    test('logoFraction is exactly 22% per Rules.md/Design_System.md', () {
      expect(EsimQr.logoFraction, 0.22);
    });
  });
}
