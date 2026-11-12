import 'package:flutter/widgets.dart';

/// Google's official multi-colour "G" mark, vector-drawn (no bundled asset
/// or extra dependency) at its native 18x18 viewBox and scaled to [size].
/// Used on "Continue with Google" per Google's sign-in button branding.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 18, size.height / 18);

    final blue = Paint()..color = const Color(0xFF4285F4);
    final blueChannel = Path()
      ..moveTo(17.64, 9.2045)
      ..relativeCubicTo(0, -0.6381, -0.0573, -1.2518, -0.1636, -1.8409)
      ..relativeLineTo(-8.4764, 0)
      ..relativeLineTo(0, 3.4814)
      ..relativeLineTo(4.8436, 0)
      ..relativeCubicTo(-0.2086, 1.125, -0.8427, 2.0782, -1.7959, 2.7164)
      ..relativeLineTo(0, 2.2581)
      ..relativeLineTo(2.9087, 0)
      ..relativeCubicTo(1.7018, -1.5668, 2.6836, -3.874, 2.6836, -6.615)
      ..close();
    canvas.drawPath(blueChannel, blue);

    final green = Paint()..color = const Color(0xFF34A853);
    final greenChannel = Path()
      ..moveTo(9, 18)
      ..relativeCubicTo(2.43, 0, 4.4673, -0.806, 5.9564, -2.1805)
      ..relativeLineTo(-2.9087, -2.2581)
      ..relativeCubicTo(-0.8059, 0.54, -1.8368, 0.8591, -3.0477, 0.8591)
      ..relativeCubicTo(-2.344, 0, -4.3282, -1.5831, -5.0359, -3.7104)
      ..relativeLineTo(-3.0068, 0)
      ..relativeLineTo(0, 2.3318)
      ..cubicTo(2.4382, 15.9832, 5.4818, 18, 9, 18)
      ..close();
    canvas.drawPath(greenChannel, green);

    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final yellowChannel = Path()
      ..moveTo(3.9641, 10.71)
      ..relativeCubicTo(-0.18, -0.54, -0.2823, -1.1168, -0.2823, -1.71)
      ..relativeCubicTo(0, -0.5932, 0.1023, -1.17, 0.2823, -1.71)
      ..relativeLineTo(0, -2.3318)
      ..relativeLineTo(-3.0068, 0)
      ..cubicTo(0.3477, 6.1732, 0, 7.5477, 0, 9)
      ..relativeCubicTo(0, 1.4523, 0.3477, 2.8268, 0.9573, 4.0418)
      ..lineTo(3.9641, 10.71)
      ..close();
    canvas.drawPath(yellowChannel, yellow);

    final red = Paint()..color = const Color(0xFFEA4335);
    final redChannel = Path()
      ..moveTo(9, 3.5795)
      ..relativeCubicTo(1.3214, 0, 2.5077, 0.4541, 3.4405, 1.346)
      ..relativeLineTo(2.5813, -2.5814)
      ..cubicTo(13.4632, 0.8918, 11.43, 0, 9, 0)
      ..cubicTo(5.4818, 0, 2.4382, 2.0168, 0.9573, 4.9582)
      ..lineTo(3.9641, 7.29)
      ..cubicTo(4.6718, 5.1627, 6.656, 3.5795, 9, 3.5795)
      ..close();
    canvas.drawPath(redChannel, red);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
