import 'package:flutter/material.dart';

/// Tokens de espaçamento baseados na grade de 4 dp (Seção 7.2 do Design System).
abstract final class AppSpacing {
  // Escala numérica básica
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Dimensões semânticas de tela e componentes
  static const double screenMargin = 16.0;
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 48.0;
  static const double bottomNavHeight = 84.0;
  static const double appBarHeight = 64.0;

  // EdgeInsets de conveniência
  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAll4 = EdgeInsets.all(space4);
  static const EdgeInsets edgeInsetsAll8 = EdgeInsets.all(space8);
  static const EdgeInsets edgeInsetsAll12 = EdgeInsets.all(space12);
  static const EdgeInsets edgeInsetsAll16 = EdgeInsets.all(space16);
  static const EdgeInsets edgeInsetsAll24 = EdgeInsets.all(space24);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenMargin);

  static const EdgeInsets dialogPadding = EdgeInsets.all(space24);

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space12,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(space16);
  static const EdgeInsets statisticCardPadding = EdgeInsets.all(space12);
}
