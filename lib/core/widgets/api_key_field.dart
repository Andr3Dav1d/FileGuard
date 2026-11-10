import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Estados semânticos do [ApiKeyField].
enum ApiKeyFieldState {
  hidden,
  visible,
  valid,
  error,
}

/// Campo de entrada para a chave de API do VirusTotal conforme Seção 8.5 do Design System.
///
/// Apresenta cantos arredondados de 16 dp, controle de alternância de visibilidade
/// com alvo de toque adequado e mensagens de validação semânticas.
class ApiKeyField extends StatefulWidget {
  const ApiKeyField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.state = ApiKeyFieldState.hidden,
    this.onToggleVisibility,
    this.errorMessage,
  });

  /// Controlador de texto do campo.
  final TextEditingController? controller;

  /// Valor inicial do campo se não houver controller.
  final String? initialValue;

  /// Callback de alteração de texto.
  final ValueChanged<String>? onChanged;

  /// Estado semântico visual inicial do campo.
  final ApiKeyFieldState state;

  /// Callback opcional ao alternar visibilidade.
  final VoidCallback? onToggleVisibility;

  /// Mensagem de erro personalizada para o estado [ApiKeyFieldState.error].
  final String? errorMessage;

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  late bool _obscureText;
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.state != ApiKeyFieldState.visible;
    _internalController = widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(ApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _obscureText = widget.state != ApiKeyFieldState.visible;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
    widget.onToggleVisibility?.call();
  }

  String _statusMessage(FileGuardColors colors) {
    switch (widget.state) {
      case ApiKeyFieldState.error:
        return widget.errorMessage ??
            'Chave inválida. Verifique e tente novamente.';
      case ApiKeyFieldState.valid:
        return 'Conectado · Chave validada';
      case ApiKeyFieldState.visible:
      case ApiKeyFieldState.hidden:
        return 'Armazenada com segurança no dispositivo.';
    }
  }

  Color _statusColor(ThemeData theme, FileGuardColors colors) {
    switch (widget.state) {
      case ApiKeyFieldState.error:
        return colors.danger;
      case ApiKeyFieldState.valid:
        return colors.neutral;
      case ApiKeyFieldState.visible:
      case ApiKeyFieldState.hidden:
        return colors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    final isError = widget.state == ApiKeyFieldState.error;
    final borderColor = isError ? colors.danger : theme.colorScheme.outline;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppShapes.borderExtraLarge,
        border: Border.all(
          color: borderColor,
          width: AppShapes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'API Key do VirusTotal',
            style: AppTypography.caption.copyWith(
              color: isError ? colors.danger : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _internalController,
                  obscureText: _obscureText,
                  onChanged: widget.onChanged,
                  style: AppTypography.body.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Insira sua chave de 64 caracteres',
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: _obscureText ? 'Mostrar chave' : 'Ocultar chave',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _toggleObscure,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space8),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 24,
                      color: colors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            _statusMessage(colors),
            style: AppTypography.caption.copyWith(
              color: _statusColor(theme, colors),
            ),
          ),
        ],
      ),
    );
  }
}
