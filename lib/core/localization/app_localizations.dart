import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Configurações e utilitários de internacionalização do FileGuard.
abstract final class AppLocalizationsSetup {
  /// Localidade padrão do aplicativo (Português - Brasil).
  static const Locale defaultLocale = Locale('pt', 'BR');

  /// Lista de localidades suportadas pelo aplicativo.
  static const List<Locale> supportedLocales = <Locale>[
    defaultLocale,
  ];

  /// Delegados padrão de internacionalização do Flutter.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
