import 'package:flutter/material.dart';

import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';

/// Card hero de resumo de análise conforme Seção 8 e Telas 14–17, 51 do Figma.
///
/// Exibe a contagem de detecções em tipografia display (~28px), título semântico,
/// subtítulo e texto explicativo preventivo.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.verdict,
    required this.stats,
    this.title,
    this.description,
    this.showDescription = true,
  });

  /// Construtor de conveniência a partir de um [ScanReport].
  factory ReportSummaryCard.fromReport(
    ScanReport report, {
    Key? key,
    String? title,
    String? description,
    bool showDescription = true,
  }) {
    return ReportSummaryCard(
      key: key,
      verdict: report.verdict,
      stats: report.stats,
      title: title,
      description: description,
      showDescription: showDescription,
    );
  }

  final ScanVerdict verdict;
  final AnalysisStats stats;
  final String? title;
  final String? description;
  final bool showDescription;

  Color _resolveStatusColor(FileGuardColors colors, ThemeData theme) {
    switch (verdict) {
      case ScanVerdict.malicious:
        return colors.danger;
      case ScanVerdict.suspicious:
        return colors.warning;
      case ScanVerdict.noDetections:
        return colors.neutral;
      case ScanVerdict.inconclusive:
        return colors.muted;
      case ScanVerdict.pending:
        return theme.colorScheme.primary;
    }
  }

  String _defaultTitle() {
    switch (verdict) {
      case ScanVerdict.malicious:
        return 'Ameaça detectada';
      case ScanVerdict.suspicious:
        return 'Comportamento suspeito';
      case ScanVerdict.noDetections:
        return 'Nenhuma detecção';
      case ScanVerdict.inconclusive:
        return 'Resultado inconclusivo';
      case ScanVerdict.pending:
        return 'Análise em andamento';
    }
  }

  String _defaultScore() {
    final total = stats.totalEngines;
    switch (verdict) {
      case ScanVerdict.malicious:
        final detected = stats.malicious + stats.suspicious;
        return '$detected / $total';
      case ScanVerdict.suspicious:
        return '${stats.suspicious} / $total';
      case ScanVerdict.noDetections:
        return '0 / $total';
      case ScanVerdict.inconclusive:
        return total > 0 ? '0 / $total' : '—';
      case ScanVerdict.pending:
        return '...';
    }
  }

  String _defaultSubtitle() {
    switch (verdict) {
      case ScanVerdict.malicious:
        return 'mecanismos detectaram uma ameaça neste relatório';
      case ScanVerdict.suspicious:
        return 'mecanismos sinalizaram comportamento suspeito';
      case ScanVerdict.noDetections:
        return 'mecanismos detectaram uma ameaça neste relatório';
      case ScanVerdict.inconclusive:
        return 'resultados de mecanismos disponíveis';
      case ScanVerdict.pending:
        return 'processando motores de análise';
    }
  }

  String _defaultDescription() {
    switch (verdict) {
      case ScanVerdict.malicious:
        return 'Múltiplos mecanismos identificaram este arquivo como malicioso. Evite executá-lo ou abri-lo.';
      case ScanVerdict.suspicious:
        return 'Alguns mecanismos identificaram comportamento suspeito. Avalie a procedência deste arquivo com cautela.';
      case ScanVerdict.noDetections:
        return 'Nenhum mecanismo detectou ameaças no relatório atual. Isso não garante que o arquivo seja seguro.';
      case ScanVerdict.inconclusive:
        return 'Este relatório possui dados incompletos ou mecanismos com falha de resposta. O resultado não é definitivo.';
      case ScanVerdict.pending:
        return 'O arquivo foi enfileirado para verificação. Os resultados serão atualizados em instantes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;
    final isDark = theme.brightness == Brightness.dark;

    final statusColor = _resolveStatusColor(colors, theme);
    final displayTitle = title ?? _defaultTitle();
    final score = _defaultScore();
    final subtitle = _defaultSubtitle();
    final explanatoryText = description ?? _defaultDescription();

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: double.infinity,
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
              // Título semântico (16px Medium)
              Text(
                displayTitle,
                style: AppTypography.cardTitle.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              // Placar numérico destacado (28px Medium conforme Figma)
              Text(
                score,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: statusColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              // Subtítulo descritivo do placar (14px Regular)
              Text(
                subtitle,
                style: AppTypography.body.copyWith(
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),

        // Texto explicativo e preventivo
        if (showDescription && explanatoryText.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space12),
          Text(
            explanatoryText,
            style: AppTypography.body.copyWith(
              color: textColor,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}
