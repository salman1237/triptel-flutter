import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Type scale from Design_System.md §1 (Plus Jakarta Sans).
class AppTypography {
  AppTypography._();

  static TextStyle _style(double size, FontWeight weight, {Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
      );

  static TextStyle display({Color? color}) =>
      _style(32, FontWeight.w800, color: color);
  static TextStyle title({Color? color}) =>
      _style(24, FontWeight.w800, color: color);
  static TextStyle headline({Color? color}) =>
      _style(20, FontWeight.w700, color: color);
  static TextStyle body({Color? color}) =>
      _style(16, FontWeight.w500, color: color);
  static TextStyle label({Color? color}) =>
      _style(14, FontWeight.w600, color: color);
  static TextStyle caption({Color? color}) =>
      _style(12, FontWeight.w500, color: color);
  static TextStyle bigNumber({Color? color}) =>
      _style(40, FontWeight.w800, color: color);
}
