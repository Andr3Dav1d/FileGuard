import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/file_guard_colors.dart';

/// Tela de Configurações - Fundação com controle de tema visual.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeColors = context.fileGuardColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.space16,
          bottom: AppSpacing.space24,
        ),
        children: <Widget>[
          Text(
            'Aparência',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space12),
          Card(
            color: themeColors.card,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Tema do Aplicativo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.brightness_auto, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('AMOLED'),
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                    ],
                    selected: <ThemeMode>{currentThemeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
