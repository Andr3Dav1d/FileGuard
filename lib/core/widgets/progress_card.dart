import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Estados possíveis do [ProgressCard].
enum ProgressCardState {
  uploading,
  analyzing,
  complete,
  failed,
}

/// Cartão de progresso de upload e análise conforme Seção 8.6 do Design System.
///
/// Apresenta título do status atual, barra de progresso horizontal planar de 8 dp
/// e texto informativo de orientação.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.state,
    this.title,
    this.description,
    this.progress,
  });

  /// Estado atual da operação.
  final ProgressCardState state;

  /// Título customizado. Se nulo, utiliza os textos padrão do design system.
  final String? title;

  /// Descrição customizada. Se nulo, utiliza os textos padrão do design system.
  final String? description;

  /// Valor de progresso de 0.0 a 1.0 (opcional).
  final double? progress;

  String _defaultTitle() {
    switch (state) {
      case ProgressCardState.uploading:
        return 'Enviando · 64%';
      case ProgressCardState.analyzing:
        return 'Analisando · 42 / 70 mecanismos';
      case ProgressCardState.complete:
        return 'Análise concluída';
      case ProgressCardState.failed:
        return 'Sem conexão com a rede';
    }
  }

  String _defaultDescription() {
    switch (state) {
      case ProgressCardState.uploading:
      case ProgressCardState.analyzing:
        return 'Você pode continuar usando o FileGuard.';
      case ProgressCardState.complete:
        return 'O relatório está pronto para abrir.';
      case ProgressCardState.failed:
        return 'Tente novamente quando estiver conectado.';
    }
  }

  double _defaultProgress() {
    switch (state) {
      case ProgressCardState.uploading:
        return 0.64;
      case ProgressCardState.analyzing:
        return 0.60;
      case ProgressCardState.complete:
        return 1.0;
      case ProgressCardState.failed:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    final resolvedTitle = title ?? _defaultTitle();
    final resolvedDescription = description ?? _defaultDescription();
    final currentProgress = (progress ?? _defaultProgress()).clamp(0.0, 1.0);

    final titleColor = state == ProgressCardState.failed
        ? colors.danger
        : theme.colorScheme.onSurface;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppShapes.borderLarge,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: AppShapes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            resolvedTitle,
            style: AppTypography.cardTitle.copyWith(color: titleColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          // Barra de progresso planar (8 dp)
          ClipRRect(
            borderRadius: AppShapes.borderMedium,
            child: Container(
              height: 8.0,
              width: double.infinity,
              color: colors.surfaceHigh,
              child: state != ProgressCardState.failed
                  ? FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: currentProgress,
                      child: Container(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            resolvedDescription,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
