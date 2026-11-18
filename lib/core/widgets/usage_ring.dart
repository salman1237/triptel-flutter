import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Circular data-usage indicator. `fraction` null means unlimited (no ring fill,
/// per Rules.md "Unlimited plans have no allowance").
class UsageRing extends StatelessWidget {
  const UsageRing(
      {super.key,
      required this.fraction,
      required this.centerText,
      this.size = 120,
      this.textColor});

  final double? fraction;
  final String centerText;
  final double size;

  /// Overrides the center label's color -- needed when the ring sits on a
  /// dark background (e.g. FR-201b's Home hero card), where the default
  /// ink color wouldn't be readable.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(fraction: fraction?.clamp(0, 1)),
          ),
          Text(centerText,
              textAlign: TextAlign.center,
              style: AppTypography.label(color: textColor)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction});
  final double? fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..color = AppColors.lilac100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (fraction == null) return;
    final fg = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * fraction!,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
