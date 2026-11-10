import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Chave seletora de preferências conforme Seção 8.7 do Design System.
///
/// Dimensões de 52 × 32 dp com cores de track e thumb ajustadas para os temas claro e escuro AMOLED.
class PreferenceSwitch extends StatelessWidget {
  const PreferenceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
  });

  /// Estado booleano atual da chave.
  final bool value;

  /// Callback acionado na alteração de estado.
  final ValueChanged<bool>? onChanged;

  /// Título opcional caso usado em linha de configuração.
  final String? title;

  /// Subtítulo opcional de apoio.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    final trackColor = value ? theme.colorScheme.primary : colors.surfaceHigh;
    final thumbColor = value ? theme.colorScheme.onPrimary : colors.muted;

    final switchWidget = Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 52.0,
          height: 32.0,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: AppShapes.borderPill,
            border: Border.all(
              color: value ? Colors.transparent : theme.colorScheme.outline,
              width: AppShapes.borderWidth,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );

    if (title == null) {
      return switchWidget;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space8,
            horizontal: AppSpacing.space4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title!,
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
              switchWidget,
            ],
          ),
        ),
      ),
    );
  }
}
