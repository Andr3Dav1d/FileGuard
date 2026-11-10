import 'package:flutter/material.dart';

/// Tokens brutos de cores do FileGuard definidos no design system.
///
/// Todas as cores foram validadas para conformidade WCAG AA e fidelidade ao Figma.
abstract final class AppColors {
  // Tema Claro - Superfícies & Fundo
  static const Color lightBackground = Color(0xFFF5F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFEAF0F4);
  static const Color lightSurfaceSecondary = Color(0xFFEAF0F4);
  static const Color lightOutline = Color(0xFFBACBD3);

  // Tema Claro - Marca & Primária
  static const Color lightPrimary = Color(0xFF08677D);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFC5EDF6);
  static const Color lightOnPrimaryContainer = Color(0xFF064A5B);

  // Tema Claro - Tipografia & Estados
  static const Color lightTextPrimary = Color(0xFF152D38);
  static const Color lightMuted = Color(0xFF50646E);
  static const Color lightDisabledText = Color(0xFF50646E);
  static const Color lightDisabledContainer = Color(0xFFEAF0F4);

  // Tema Claro - Risco & Feedback
  static const Color lightDanger = Color(0xFFAA2733);
  static const Color lightDangerContainer = Color(0xFFFFE9EB);
  static const Color lightWarning = Color(0xFF795600);
  static const Color lightWarningContainer = Color(0xFFFFF0CC);
  static const Color lightNeutral = Color(0xFF38685E);
  static const Color lightNeutralContainer = Color(0xFFDBF1EA);

  // Tema Escuro AMOLED - Superfícies & Fundo
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF000000);
  static const Color darkCard = Color(0xFF101010);
  static const Color darkSurfaceHigh = Color(0xFF0A0A0A);
  static const Color darkSurfaceSecondary = Color(0xFF121212);
  static const Color darkOutline = Color(0xFF252525);

  // Tema Escuro AMOLED - Marca & Primária
  static const Color darkPrimary = Color(0xFF80B4FF);
  static const Color darkOnPrimary = Color(0xFF001C3B);
  static const Color darkPrimaryContainer = Color(0xFF10233B);
  static const Color darkOnPrimaryContainer = Color(0xFFCFE2FF);

  // Tema Escuro AMOLED - Tipografia & Estados
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkMuted = Color(0xFFB3B3B3);
  static const Color darkDisabledText = Color(0xFF666666);
  static const Color darkDisabledContainer = Color(0xFF121212);

  // Tema Escuro AMOLED - Risco & Feedback
  static const Color darkDanger = Color(0xFFFFB4AB);
  static const Color darkDangerContainer = Color(0x26FFB4AB); // ~15% opacidade
  static const Color darkWarning = Color(0xFFFFD180);
  static const Color darkWarningContainer = Color(0x26FFD180); // ~15% opacidade
  static const Color darkNeutral = Color(0xFF8FD5A6);
  static const Color darkNeutralContainer = Color(0x268FD5A6); // ~15% opacidade

  // Neutro comum
  static const Color modalScrim = Color(0x7505121A); // rgba(5, 18, 26, 0.46)
}
