import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/file_guard_colors.dart';
import '../../../../core/widgets/api_key_field.dart';
import '../../../../core/widgets/file_guard_button.dart';
import '../../domain/models/api_key_status.dart';
import '../providers/api_key_provider.dart';

/// Tela de Configurações - Gerenciamento seguro da API Key, aparência e diagnóstico.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _keyController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  ApiKeyFieldState _resolveFieldState(ApiKeyState state) {
    switch (state.status) {
      case ApiKeyStatus.valid:
        return ApiKeyFieldState.valid;
      case ApiKeyStatus.invalid:
      case ApiKeyStatus.quotaExceeded:
      case ApiKeyStatus.networkError:
      case ApiKeyStatus.temporaryError:
        return ApiKeyFieldState.error;
      case ApiKeyStatus.validating:
      case ApiKeyStatus.notConfigured:
        return ApiKeyFieldState.hidden;
    }
  }

  Future<void> _handleSave() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma chave de API para validar.'),
        ),
      );
      return;
    }

    final success =
        await ref.read(apiKeyNotifierProvider.notifier).saveAndValidate(key);

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key validada e salva com sucesso!'),
          ),
        );
      } else {
        final status = ref.read(apiKeyNotifierProvider).status;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao validar chave: ${status.description}'),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover API Key?'),
        content: const Text(
          'A chave será excluída com segurança do dispositivo. '
          'Você precisará configurá-la novamente para realizar novas consultas.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(apiKeyNotifierProvider.notifier).deleteKey();
      _keyController.clear();
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key removida do armazenamento seguro.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final apiKeyState = ref.watch(apiKeyNotifierProvider);
    final themeColors = context.fileGuardColors;
    final theme = Theme.of(context);

    // Sincroniza o controller apenas se o usuário não estiver ativamente digitando
    if (!_isEditing && apiKeyState.apiKey != null && _keyController.text.isEmpty) {
      _keyController.text = apiKeyState.apiKey!;
    }

    final fieldState = _resolveFieldState(apiKeyState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.space16,
          bottom: AppSpacing.space32,
        ),
        children: <Widget>[
          // Seção 1: API Key do VirusTotal
          Text(
            'API do VirusTotal',
            style: AppTypography.subheading.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Para analisar arquivos e hashes, insira sua chave pessoal obtida em virustotal.com. '
            'Ela é armazenada com criptografia de hardware no dispositivo.',
            style: AppTypography.caption.copyWith(
              color: themeColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          ApiKeyField(
            controller: _keyController,
            state: fieldState,
            errorMessage: apiKeyState.statusMessage ?? apiKeyState.status.description,
            onChanged: (val) {
              if (!_isEditing) {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.space12),

          // Ações da API Key
          FileGuardButton(
            label: apiKeyState.hasKey && !_isEditing
                ? 'Revalidar Conexão'
                : 'Salvar e Validar',
            icon: Icons.check_circle_outline,
            isLoading: apiKeyState.isLoading,
            onPressed: () {
              if (apiKeyState.hasKey && !_isEditing) {
                ref.read(apiKeyNotifierProvider.notifier).revalidateCurrentKey();
              } else {
                _handleSave();
              }
            },
          ),
          if (apiKeyState.hasKey) ...<Widget>[
            const SizedBox(height: AppSpacing.space8),
            FileGuardButton(
              label: 'Remover Chave',
              icon: Icons.delete_outline,
              style: FileGuardButtonStyle.danger,
              onPressed: apiKeyState.isLoading ? null : _handleDeleteConfirmation,
            ),
          ],

          const SizedBox(height: AppSpacing.space24),

          // Seção 2: Aparência e Tema
          Text(
            'Aparência',
            style: AppTypography.subheading.copyWith(
              color: theme.colorScheme.onSurface,
            ),
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
                    style: AppTypography.cardTitle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
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

          const SizedBox(height: AppSpacing.space24),

          // Seção 3: Privacidade e Diagnóstico
          Text(
            'Privacidade e Segurança',
            style: AppTypography.subheading.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: themeColors.card,
              borderRadius: AppShapes.borderLarge,
              border: Border.all(
                color: theme.colorScheme.outline,
                width: AppShapes.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.shield_outlined, color: themeColors.neutral, size: 20),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'Compromisso de Privacidade',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  '• Nenhuma chave ou hash é enviado a servidores próprios.\n'
                  '• A API Key reside apenas no Android Keystore.\n'
                  '• Nenhum arquivo é enviado ao VirusTotal sem sua autorização explícita.\n'
                  '• O histórico de análises é mantido 100% offline no dispositivo.',
                  style: AppTypography.caption.copyWith(
                    color: themeColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          FileGuardButton(
            label: 'Rever Apresentação e Boas-Vindas',
            icon: Icons.menu_book_outlined,
            style: FileGuardButtonStyle.tonal,
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
        ],
      ),
    );
  }
}
