import 'package:flutter/material.dart';
import 'tokens.dart';
import 'typography.dart';

/// Material [ThemeData] built from the Triptel tokens. Used once at the app root.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.lilac50,
    fontFamily: AppTypography.body().fontFamily,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: AppTypography.display(),
      titleLarge: AppTypography.title(),
      headlineSmall: AppTypography.headline(),
      bodyLarge: AppTypography.body(),
      labelLarge: AppTypography.label(),
      bodySmall: AppTypography.caption(),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lilac50,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    dividerColor: AppColors.line,
  );
}
