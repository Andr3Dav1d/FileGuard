import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'file_guard_colors.dart';

/// Configuração do ThemeData para o FileGuard seguindo a arquitetura planar
/// e conformidade de acessibilidade para temas Claro e Escuro AMOLED.
abstract final class AppTheme {
  /// Tema Claro
  static ThemeData get light {
    final textTheme = AppTypography.createTextTheme(AppColors.lightTextPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnPrimaryContainer,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightOutline,
        error: AppColors.lightDanger,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.appBarTitle.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppShapes.cardShape.copyWith(
          side: const BorderSide(
            color: AppColors.lightOutline,
            width: AppShapes.borderWidth,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: AppShapes.dialogShape,
        titleTextStyle: AppTypography.dialogTitle.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurfaceHigh,
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        indicatorColor: AppColors.lightPrimaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.lightOnPrimaryContainer,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.lightMuted,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.micro.copyWith(
              color: AppColors.lightOnPrimaryContainer,
            );
          }
          return AppTypography.micro.copyWith(
            color: AppColors.lightMuted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightOutline,
        thickness: AppShapes.borderWidth,
        space: AppShapes.borderWidth,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        FileGuardColors.light,
      ],
    );
  }

  /// Tema Escuro AMOLED (Fundo Preto Absoluto #000000 e modelo planar)
  static ThemeData get dark {
    final textTheme = AppTypography.createTextTheme(AppColors.darkTextPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkOutline,
        error: AppColors.darkDanger,
        onError: AppColors.darkOnPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.appBarTitle.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppShapes.cardShape.copyWith(
          side: const BorderSide(
            color: AppColors.darkOutline,
            width: AppShapes.borderWidth,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        shape: AppShapes.dialogShape.copyWith(
          side: const BorderSide(
            color: AppColors.darkOutline,
            width: AppShapes.borderWidth,
          ),
        ),
        titleTextStyle: AppTypography.dialogTitle.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceHigh,
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        indicatorColor: AppColors.darkPrimaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.darkOnPrimaryContainer,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.darkMuted,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.micro.copyWith(
              color: AppColors.darkOnPrimaryContainer,
            );
          }
          return AppTypography.micro.copyWith(
            color: AppColors.darkMuted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkOutline,
        thickness: AppShapes.borderWidth,
        space: AppShapes.borderWidth,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        FileGuardColors.dark,
      ],
    );
  }
}
