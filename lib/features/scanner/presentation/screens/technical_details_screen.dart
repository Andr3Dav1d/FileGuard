import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/utils/file_size_formatter.dart';
import 'package:fileguard/core/widgets/file_guard_app_bar.dart';
import 'package:fileguard/core/widgets/file_guard_button.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/presentation/widgets/engine_report_table.dart';

/// Tela de detalhes técnicos de uma análise, conforme Tela 42 do Figma (nodes 6:1429 e 6:5122).
///
/// Exibe metadados completos do arquivo, impressões digitais criptográficas (SHA-256,
/// MD5, SHA-1) com cópia acessível, reputação e tags da comunidade, e tabela detalhada de
/// mecanismos antivírus com resumo inferior.
class TechnicalDetailsScreen extends StatelessWidget {
  const TechnicalDetailsScreen({
    super.key,
    required this.report,
  });

  /// Relatório de análise do VirusTotal a ser exibido.
  final ScanReport report;

  Future<void> _copyHash(BuildContext context, String hash, String hashName) async {
    await Clipboard.setData(ClipboardData(text: hash));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$hashName copiado para a área de transferência.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final utcFormattedDate = report.scanDate.millisecondsSinceEpoch <= 0
        ? 'Data não disponível'
        : DateFormat("dd/MM/yyyy, HH:mm 'UTC'").format(report.scanDate.toUtc());

    // Resumo dos contadores para a nota informativa inferior
    final threatsCount = report.results.isNotEmpty
        ? report.threatEngines.length
        : (report.stats.malicious + report.stats.suspicious);
    final cleanCount = report.results.isNotEmpty
        ? report.cleanEngines.length
        : (report.stats.undetected + report.stats.harmless);
    final totalCount = report.results.isNotEmpty
        ? report.results.length
        : report.stats.totalEngines;

    final detectionsText =
        threatsCount == 1 ? '1 detecção' : '$threatsCount detecções';
    final noDetectionsText =
        cleanCount == 1 ? '1 sem detecção' : '$cleanCount sem detecção';
    final otherCount = totalCount - (threatsCount + cleanCount);
    final otherText =
        otherCount == 1 ? '1 não analisado' : '$otherCount não analisados';
    final totalText =
        totalCount == 1 ? '1 mecanismo' : '$totalCount mecanismos';

    final summaryFormulaText = otherCount > 0
        ? '$detectionsText + $noDetectionsText + $otherText = $totalText.'
        : '$detectionsText + $noDetectionsText = $totalText.';

    final hasCommunityData = report.reputation != null ||
        report.totalVotes != null ||
        report.tags.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const FileGuardAppBar(
        title: 'Detalhes técnicos',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
            vertical: AppSpacing.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Card Metadados do Arquivo (Figma 6:2268 / 6:5130)
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: AppShapes.borderLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Metadados do arquivo',
                      style: AppTypography.cardTitle.copyWith(
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _buildMetadataRow('Nome', report.fileName, primaryTextColor, secondaryTextColor),
                    _buildMetadataRow('Tamanho', FileSizeFormatter.format(report.fileSize), primaryTextColor, secondaryTextColor),
                    if (report.mimeType != null && report.mimeType!.isNotEmpty)
                      _buildMetadataRow('MIME', report.mimeType!, primaryTextColor, secondaryTextColor),
                    if (report.fileExtension != null && report.fileExtension!.isNotEmpty)
                      _buildMetadataRow('Extensão', report.fileExtension!, primaryTextColor, secondaryTextColor),
                    _buildMetadataRow('Relatório', utcFormattedDate, primaryTextColor, secondaryTextColor),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space12),

              // 2. Impressão Digital SHA-256 (Figma 6:2271 / 6:5133)
              _buildHashCard(
                context: context,
                title: 'Impressão digital SHA-256',
                hash: report.sha256,
                label: 'SHA-256',
                colors: colors,
                primaryTextColor: primaryTextColor,
              ),

              // Hashes Adicionais (MD5 e SHA-1 se disponíveis)
              if (report.md5 != null && report.md5!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.space12),
                _buildHashCard(
                  context: context,
                  title: 'Impressão digital MD5',
                  hash: report.md5!,
                  label: 'MD5',
                  colors: colors,
                  primaryTextColor: primaryTextColor,
                ),
              ],
              if (report.sha1 != null && report.sha1!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.space12),
                _buildHashCard(
                  context: context,
                  title: 'Impressão digital SHA-1',
                  hash: report.sha1!,
                  label: 'SHA-1',
                  colors: colors,
                  primaryTextColor: primaryTextColor,
                ),
              ],

              // 3. Reputação e Tags da Comunidade (se disponíveis)
              if (hasCommunityData) ...<Widget>[
                const SizedBox(height: AppSpacing.space12),
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: AppShapes.borderLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Comunidade VirusTotal',
                        style: AppTypography.cardTitle.copyWith(
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      if (report.reputation != null) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Reputação: ',
                              style: AppTypography.bodyCompact.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space8,
                                vertical: AppSpacing.space2,
                              ),
                              decoration: BoxDecoration(
                                color: _resolveReputationColor(report.reputation!, colors)
                                    .withValues(alpha: 0.15),
                                borderRadius: AppShapes.borderSmall,
                              ),
                              child: Text(
                                report.reputation! > 0
                                    ? '+${report.reputation}'
                                    : '${report.reputation}',
                                style: AppTypography.bodyCompact.copyWith(
                                  color: _resolveReputationColor(report.reputation!, colors),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space8),
                      ],
                      if (report.totalVotes != null) ...<Widget>[
                        Text(
                          'Votos da comunidade: ${report.totalVotes!.harmless} inofensivo(s) · ${report.totalVotes!.malicious} malicioso(s)',
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        if (report.tags.isNotEmpty) const SizedBox(height: AppSpacing.space8),
                      ],
                      if (report.tags.isNotEmpty) ...<Widget>[
                        Wrap(
                          spacing: AppSpacing.space8,
                          runSpacing: AppSpacing.space4,
                          children: report.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space8,
                                vertical: AppSpacing.space4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceHigh,
                                borderRadius: AppShapes.borderMedium,
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.caption.copyWith(
                                  color: primaryTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space16),

              // 4. Tabela de Mecanismos de Segurança (Etapa 4)
              EngineReportTable(
                results: report.results,
                title: 'Todos os resultados dos mecanismos',
              ),
              const SizedBox(height: AppSpacing.space12),

              // 5. Nota de Resumo Inferior (Figma 6:2313 / 6:5171)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: AppSpacing.space8,
                ),
                decoration: const BoxDecoration(
                  borderRadius: AppShapes.borderLarge,
                ),
                child: Text(
                  summaryFormulaText,
                  style: AppTypography.bodyCompact.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }

  Color _resolveReputationColor(int reputation, FileGuardColors colors) {
    if (reputation > 0) return colors.neutral;
    if (reputation < 0) return colors.danger;
    return colors.muted;
  }

  Widget _buildMetadataRow(
    String label,
    String value,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTypography.bodyCompact.copyWith(
                color: secondaryColor,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTypography.bodyCompact.copyWith(
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashCard({
    required BuildContext context,
    required String title,
    required String hash,
    required String label,
    required FileGuardColors colors,
    required Color primaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppShapes.borderLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          SelectableText(
            hash,
            style: AppTypography.technical.copyWith(
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Semantics(
            button: true,
            label: 'Copiar $label para a área de transferência',
            child: FileGuardButton(
              label: 'Copiar $label',
              style: FileGuardButtonStyle.tonal,
              icon: Icons.copy_rounded,
              onPressed: () => _copyHash(context, hash, label),
            ),
          ),
        ],
      ),
    );
  }
}
