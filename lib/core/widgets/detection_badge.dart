import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Estados semânticos possíveis para o [DetectionBadge].
enum DetectionBadgeStatus {
  malicious,
  suspicious,
  noDetections,
  inconclusive,
  pending,
}

/// Badge de status de detecção conforme Seção 8.2 do Design System.
///
/// Exibe ícone indicador, texto semântico e contêiner com cores de risco.
class DetectionBadge extends StatelessWidget {
  const DetectionBadge({
    super.key,
    required this.status,
    this.label,
    this.isFullWidth = false,
  });

  /// Status de detecção representado pelo badge.
  final DetectionBadgeStatus status;

  /// Rótulo opcional. Se não informado, utiliza o texto padrão em português.
  final String? label;

  /// Se deve ocupar a largura disponível do contêiner pai.
  final bool isFullWidth;

  String _defaultLabel() {
    switch (status) {
      case DetectionBadgeStatus.malicious:
        return '12 / 70 · Malicioso';
      case DetectionBadgeStatus.suspicious:
        return '2 / 70 · Suspeito';
      case DetectionBadgeStatus.noDetections:
        return '0 / 70 · Nenhuma detecção';
      case DetectionBadgeStatus.inconclusive:
        return '18 / 70 · Inconclusivo';
      case DetectionBadgeStatus.pending:
        return 'Pendente';
    }
  }

  IconData _icon() {
    switch (status) {
      case DetectionBadgeStatus.malicious:
      case DetectionBadgeStatus.suspicious:
        return Icons.warning_amber_rounded;
      case DetectionBadgeStatus.noDetections:
        return Icons.check_circle_outline_rounded;
      case DetectionBadgeStatus.inconclusive:
      case DetectionBadgeStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    Color containerColor;
    Color contentColor;

    switch (status) {
      case DetectionBadgeStatus.malicious:
        containerColor = colors.dangerContainer;
        contentColor = colors.danger;
        break;
      case DetectionBadgeStatus.suspicious:
        containerColor = colors.warningContainer;
        contentColor = colors.warning;
        break;
      case DetectionBadgeStatus.noDetections:
        containerColor = colors.neutralContainer;
        contentColor = colors.neutral;
        break;
      case DetectionBadgeStatus.inconclusive:
        containerColor = colors.surfaceSecondary;
        contentColor = colors.muted;
        break;
      case DetectionBadgeStatus.pending:
        containerColor = theme.colorScheme.primaryContainer;
        contentColor = theme.colorScheme.primary;
        break;
    }

    final displayText = label ?? _defaultLabel();

    final badgeContent = Container(
      padding: AppSpacing.statisticCardPadding,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: AppShapes.borderLarge,
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          Icon(
            _icon(),
            size: 24,
            color: contentColor,
          ),
          const SizedBox(width: AppSpacing.space12),
          Flexible(
            child: Text(
              displayText,
              style: AppTypography.bodyCompact.copyWith(
                color: contentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
