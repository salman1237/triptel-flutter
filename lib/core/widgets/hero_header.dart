import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Dark hero header with a curved bottom edge (Design_System.md §2, Home/Account).
class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          56,
          AppSpacing.gutter,
          36,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.night, AppColors.primaryDeep],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 28);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 28);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
