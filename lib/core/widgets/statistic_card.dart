import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Tipos semânticos do [StatisticCard].
enum StatisticCardType {
  total,
  malicious,
  suspicious,
  pending,
}

/// Cartão de estatísticas e métricas conforme Seção 8 do Design System.
///
/// Exibe valor numérico de destaque (28px) e rótulo explicativo (12px),
/// adaptando-se a layouts flexíveis em `Row` ou `Grid`.
class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.value,
    required this.label,
    this.type = StatisticCardType.total,
    this.onTap,
  });

  /// Valor numérico a ser exibido em destaque (ex.: "128", "8").
  final String value;

  /// Rótulo explicativo (ex.: "Analisados", "Maliciosos").
  final String label;

  /// Tipo semântico que determina a cor do número.
  final StatisticCardType type;

  /// Callback opcional de toque.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    Color valueColor;
    switch (type) {
      case StatisticCardType.total:
        valueColor = theme.colorScheme.primary;
        break;
      case StatisticCardType.malicious:
        valueColor = colors.danger;
        break;
      case StatisticCardType.suspicious:
        valueColor = colors.warning;
        break;
      case StatisticCardType.pending:
        valueColor = theme.colorScheme.primary;
        break;
    }

    final cardContent = Padding(
      padding: AppSpacing.statisticCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: AppTypography.statistic.copyWith(color: valueColor),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: colors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.borderLarge,
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: AppShapes.borderWidth,
        ),
      ),
      child: onTap != null
          ? InkWell(
              borderRadius: AppShapes.borderLarge,
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
