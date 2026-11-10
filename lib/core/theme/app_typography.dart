import 'package:flutter/material.dart';

/// Tokens e estilos tipográficos definidos na Seção 7.1 do Design System (Roboto).
abstract final class AppTypography {
  static const String fontFamily = 'Roboto';

  // 1. Headline / Tela: 28px / 36px (h: 36/28), Medium
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // 2. Estatística (contadores numéricos nos cartões): 28px / 34px, Medium
  static const TextStyle statistic = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  // 3. App Bar Title: 20px / 28px, Medium
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // 4. Dialog Title: 20px / 28px, Bold
  static const TextStyle dialogTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // 5. Subtítulo / Seção: 18px / 26px, Medium
  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // 6. Card Title / Alerta: 16px / 24px, Medium
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  // 7. Corpo Padrão: 16px / 24px, Regular
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  // 8. Corpo Compacto / Botões: 14px / 20px, Medium
  static const TextStyle bodyCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // 9. Técnico (SHA-256 / Hashes / Motores): 13px / 20px, Regular (Monospace)
  static const TextStyle technical = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: <String>['Courier New', 'Courier'],
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // 10. Apoio / Metadados: 12px / 16px, Regular
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // 11. Micro / Rótulos da Bottom Nav: 11px / 16px, Medium
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  /// Cria o TextTheme base para o ThemeData do Material 3
  static TextTheme createTextTheme(Color defaultTextColor) {
    return TextTheme(
      headlineLarge: headline.copyWith(color: defaultTextColor),
      headlineMedium: headline.copyWith(color: defaultTextColor),
      titleLarge: appBarTitle.copyWith(color: defaultTextColor),
      titleMedium: subheading.copyWith(color: defaultTextColor),
      titleSmall: cardTitle.copyWith(color: defaultTextColor),
      bodyLarge: body.copyWith(color: defaultTextColor),
      bodyMedium: bodyCompact.copyWith(color: defaultTextColor),
      bodySmall: caption.copyWith(color: defaultTextColor),
      labelLarge: bodyCompact.copyWith(color: defaultTextColor),
      labelMedium: caption.copyWith(color: defaultTextColor),
      labelSmall: micro.copyWith(color: defaultTextColor),
    );
  }
}
