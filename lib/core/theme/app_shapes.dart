import 'package:flutter/material.dart';

/// Tokens de formas e raios de curvatura (Corner Radius) definidos no Design System.
abstract final class AppShapes {
  // Raios numéricos (Seção 7.2)
  static const double radiusSmall = 4.0; // Gesture handle do Android
  static const double radiusMedium = 8.0; // File list tile, barra de progresso
  static const double radiusLarge = 12.0; // Cartões, botões, badges
  static const double radiusExtraLarge = 16.0; // Campos de API Key, contêineres de ícones
  static const double radiusDialog = 28.0; // Diálogos de permissão (M3 extraLarge)
  static const double radiusPill = 100.0; // Pílula total (indicador nav bar)

  // Espessura padrão de contornos e bordas planares (Seção 1)
  static const double borderWidth = 1.0;

  // BorderRadius pré-configurados
  static const BorderRadius borderSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderExtraLarge =
      BorderRadius.all(Radius.circular(radiusExtraLarge));
  static const BorderRadius borderDialog =
      BorderRadius.all(Radius.circular(radiusDialog));
  static const BorderRadius borderPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // RoundedRectangleBorder para botões, cartões e diálogos
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: borderLarge,
  );

  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: borderLarge,
  );

  static const RoundedRectangleBorder inputShape = RoundedRectangleBorder(
    borderRadius: borderExtraLarge,
  );

  static const RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: borderDialog,
  );
}
