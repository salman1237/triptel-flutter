import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/theme/tokens.dart';
import 'package:triptel/core/theme/typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors', () {
    test('matches the Design_System.md §1 palette', () {
      expect(AppColors.primary, const Color(0xFF5E3CDA));
      expect(AppColors.primaryDeep, const Color(0xFF452C9B));
      expect(AppColors.night, const Color(0xFF1B1145));
      expect(AppColors.lilac50, const Color(0xFFF5F2FF));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.ink, const Color(0xFF16123A));
      expect(AppColors.success, const Color(0xFF16A34A));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.danger, const Color(0xFFE5484D));
    });
  });

  group('AppRadius', () {
    test('matches the shape scale', () {
      expect(AppRadius.card, 24);
      expect(AppRadius.sheet, 28);
      expect(AppRadius.pill, 999);
    });
  });

  group('AppTypography', () {
    test('weights follow the Design_System.md type scale', () {
      expect(AppTypography.display().fontSize, 32);
      expect(AppTypography.display().fontWeight, FontWeight.w800);
      expect(AppTypography.title().fontSize, 24);
      expect(AppTypography.headline().fontSize, 20);
      expect(AppTypography.body().fontSize, 16);
      expect(AppTypography.label().fontSize, 14);
      expect(AppTypography.caption().fontSize, 12);
    });
  });
}
