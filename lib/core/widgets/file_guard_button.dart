import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Estilos visuais disponíveis para o [FileGuardButton].
enum FileGuardButtonStyle {
  filled,
  tonal,
  danger,
}

/// Botão padrão do FileGuard seguindo a Seção 8.1 do Design System.
///
/// Possui altura fixa de 48 dp, raio de 12 dp e estados para Filled, Tonal, Danger,
/// Disabled e Loading.
class FileGuardButton extends StatelessWidget {
  const FileGuardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = FileGuardButtonStyle.filled,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  /// Rótulo de texto do botão (14px Medium).
  final String label;

  /// Callback de clique. Se nulo, o botão é renderizado no estado desabilitado.
  final VoidCallback? onPressed;

  /// Estilo visual do botão.
  final FileGuardButtonStyle style;

  /// Se verdadeiro, exibe indicador de progresso e bloqueia cliques.
  final bool isLoading;

  /// Se deve expandir horizontalmente para ocupar a largura disponível.
  final bool isFullWidth;

  /// Ícone opcional exibido antes do rótulo.
  final IconData? icon;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    if (!_isEnabled && !isLoading) {
      backgroundColor = colors.disabledContainer;
      foregroundColor = colors.disabledText;
    } else {
      switch (style) {
        case FileGuardButtonStyle.filled:
          backgroundColor = theme.colorScheme.primary;
          foregroundColor = theme.colorScheme.onPrimary;
          break;
        case FileGuardButtonStyle.tonal:
          backgroundColor = Colors.transparent;
          foregroundColor = theme.colorScheme.primary;
          borderSide = BorderSide(
            color: theme.colorScheme.outline,
            width: AppShapes.borderWidth,
          );
          break;
        case FileGuardButtonStyle.danger:
          backgroundColor = colors.danger;
          foregroundColor = theme.brightness == Brightness.dark
              ? const Color(0xFF001C3B)
              : Colors.white;
          break;
      }
    }

    Widget content;
    if (isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Text(
            'Carregando…',
            style: AppTypography.bodyCompact.copyWith(color: foregroundColor),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: AppSpacing.space8),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodyCompact.copyWith(color: foregroundColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final buttonWidget = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.borderLarge,
        side: borderSide ?? BorderSide.none,
      ),
      child: InkWell(
        borderRadius: AppShapes.borderLarge,
        onTap: _isEnabled ? onPressed : null,
        child: Container(
          height: AppSpacing.buttonHeight,
          padding: AppSpacing.buttonPadding,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
