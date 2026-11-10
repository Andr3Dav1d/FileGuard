import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme & FileGuardColors Tests', () {
    test('Tema claro deve conter FileGuardColors.light configurado', () {
      final theme = AppTheme.light;
      final extension = theme.extension<FileGuardColors>();

      expect(extension, isNotNull);
      expect(extension!.card, equals(AppColors.lightCard));
      expect(extension.danger, equals(AppColors.lightDanger));
      expect(extension.warning, equals(AppColors.lightWarning));
      expect(extension.neutral, equals(AppColors.lightNeutral));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
    });

    test('Tema escuro AMOLED deve ter fundo preto absoluto #000000', () {
      final theme = AppTheme.dark;
      final extension = theme.extension<FileGuardColors>();

      expect(extension, isNotNull);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
      expect(theme.colorScheme.surface, equals(const Color(0xFF000000)));
      expect(extension!.card, equals(AppColors.darkCard));
      expect(extension.surfaceHigh, equals(AppColors.darkSurfaceHigh));
      expect(extension.surfaceSecondary, equals(AppColors.darkSurfaceSecondary));
      expect(extension.danger, equals(AppColors.darkDanger));
    });

    test('FileGuardColors copyWith e lerp funcionam adequadamente', () {
      final light = FileGuardColors.light;
      final dark = FileGuardColors.dark;

      final copied = light.copyWith(card: const Color(0xFF112233));
      expect(copied.card, equals(const Color(0xFF112233)));
      expect(copied.danger, equals(light.danger));

      final lerped = light.lerp(dark, 0.5);
      expect(lerped, isNotNull);
      expect(lerped.card, equals(Color.lerp(light.card, dark.card, 0.5)));
    });
  });
}
