import 'package:flutter/widgets.dart';

/// Colour tokens from Design_System.md §1. Features must use these, never raw hex.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF5E3CDA);
  static const primaryDeep = Color(0xFF452C9B);
  static const night = Color(0xFF1B1145);
  static const nightSoft = Color(0xFF2A1A6B);
  static const sky = Color(0xFF3AA0F0);
  static const lilac50 = Color(0xFFF5F2FF);
  static const lilac100 = Color(0xFFEBE5FF);
  static const lilac200 = Color(0xFFD6CCFF);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16123A);
  static const inkMuted = Color(0xFF6B6790);
  static const line = Color(0xFFE7E4F2);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE5484D);
  static const promo = Color(0xFFC026D3);
}

/// Shape tokens from Design_System.md §1.
class AppRadius {
  AppRadius._();

  static const card = 24.0;
  static const sheet = 28.0;
  static const pill = 999.0;
  static const input = 999.0;
  static const smallTag = 8.0;
}

/// Spacing grid of 4; screen gutter 20.
class AppSpacing {
  AppSpacing._();

  static const unit = 4.0;
  static const gutter = 20.0;

  static double of(int units) => unit * units;
}

const appCardShadow = BoxShadow(
  color: Color(0x142E1778), // rgba(46, 23, 120, 0.08)
  blurRadius: 24,
  offset: Offset(0, 8),
);
