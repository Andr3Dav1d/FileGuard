import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Provedor para gerenciar o modo de tema atual (Claro, Escuro AMOLED ou Sistema).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
}

/// Widget raiz do aplicativo FileGuard.
class FileGuardApp extends ConsumerWidget {
  const FileGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FileGuard',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      supportedLocales: AppLocalizationsSetup.supportedLocales,
      localizationsDelegates: AppLocalizationsSetup.localizationsDelegates,
    );
  }
}
