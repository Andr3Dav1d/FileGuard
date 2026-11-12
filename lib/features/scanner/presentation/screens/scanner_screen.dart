import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/utils/file_size_formatter.dart';
import 'package:fileguard/core/widgets/file_guard_app_bar.dart';
import 'package:fileguard/core/widgets/file_guard_button.dart';
import 'package:fileguard/core/widgets/permission_dialog.dart';
import 'package:fileguard/core/widgets/progress_card.dart';
import 'package:fileguard/core/widgets/scan_fab.dart';
import 'package:fileguard/features/history/data/services/backup_service.dart';
import 'package:fileguard/features/scanner/data/services/apk_install_service.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:fileguard/features/scanner/presentation/widgets/report_summary_card.dart';

/// Tela principal do Analisador de Arquivos e APKs.
///
/// Implementa o fluxo de seleção, análise com VirusTotal e exibição consolidada
/// conforme a Tela 51 do Figma (nodes 6:7766 e 6:7937).
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  String _resolveFileType(ScanReport report) {
    if (report.fileExtension != null && report.fileExtension!.isNotEmpty) {
      return report.fileExtension!.replaceAll('.', '').toUpperCase();
    }
    if (report.fileName.contains('.')) {
      return report.fileName.split('.').last.toUpperCase();
    }
    if (report.mimeType != null && report.mimeType!.isNotEmpty) {
      return report.mimeType!.split('/').last.toUpperCase();
    }
    return 'ARQUIVO';
  }

  List<EngineResult> _selectPreviewEngines(ScanReport report) {
    if (report.results.isEmpty) return const [];
    // Prioriza motores que detectaram ameaças (malicious ou suspicious)
    final threats = report.threatEngines;
    if (threats.length >= 3) {
      return threats.take(3).toList();
    }
    final selected = <EngineResult>[...threats];
    for (final engine in report.results.values) {
      if (selected.length >= 3) break;
      if (!selected.any((e) => e.engineName == engine.engineName)) {
        selected.add(engine);
      }
    }
    return selected;
  }

  (String, Color) _resolvePreviewEngineDisplay(
    EngineResult engine,
    FileGuardColors colors,
  ) {
    if (engine.isMalicious) {
      return (engine.result ?? 'Malicioso', colors.danger);
    }
    if (engine.isSuspicious) {
      return (engine.result ?? 'Suspeito', colors.warning);
    }
    if (engine.isUndetected || engine.isHarmless) {
      return ('Nenhuma detecção', colors.neutral);
    }
    switch (engine.engineCategory) {
      case EngineCategory.timeout:
        return ('Timeout', colors.muted);
      case EngineCategory.failure:
        return ('Falha', colors.muted);
      case EngineCategory.typeUnsupported:
        return ('Não suportado', colors.muted);
      default:
        return (engine.result ?? 'Sem dados', colors.muted);
    }
  }

  void _shareReport(ScanReport report) {
    final detections = report.stats.malicious + report.stats.suspicious;
    final text = 'Relatório FileGuard — VirusTotal:\n'
        'Arquivo: ${report.fileName}\n'
        'Tamanho: ${FileSizeFormatter.format(report.fileSize)}\n'
        'Veredito: ${report.verdict.name.toUpperCase()}\n'
        'Detecções: $detections de ${report.stats.totalEngines} motores\n'
        'SHA-256: ${report.sha256}\n'
        'Data: ${DateFormat("dd/MM/yyyy, HH:mm 'UTC'").format(report.scanDate.toUtc())}\n'
        'Link: ${report.permalink ?? "https://www.virustotal.com/gui/file/${report.sha256}"}';
    SharePlus.instance.share(
      ShareParams(text: text, subject: 'Relatório FileGuard - ${report.fileName}'),
    );
  }

  void _exportReport(BuildContext context, ScanReport report) {
    try {
      final jsonExport = const BackupService().exportToJson([report]);
      SharePlus.instance.share(
        ShareParams(
          text: jsonExport,
          subject: 'Exportação Relatório FileGuard - ${report.fileName}.json',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao exportar relatório em formato JSON.'),
          ),
        );
      }
    }
  }

  Future<void> _openVirusTotal(BuildContext context, ScanReport report) async {
    final urlString = (report.permalink != null && report.permalink!.isNotEmpty)
        ? report.permalink!
        : 'https://www.virustotal.com/gui/file/${report.sha256}';

    final uri = Uri.tryParse(urlString);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL do relatório é inválida.')),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link externamente.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao abrir o navegador para o VirusTotal.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerNotifierProvider);
    final notifier = ref.read(scannerNotifierProvider.notifier);
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: FileGuardAppBar(
        title: state.step == ScannerStep.completed
            ? 'Resultado da análise'
            : 'Analisador',
        actions: <Widget>[
          if (state.step == ScannerStep.completed ||
              state.step == ScannerStep.error ||
              state.step == ScannerStep.queued)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Nova Análise',
              onPressed: notifier.reset,
            ),
        ],
      ),
      floatingActionButton: state.step == ScannerStep.idle
          ? ScanFAB(
              onPressed: notifier.pickAndScan,
            )
          : null,
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.space16,
          bottom: AppSpacing.space40,
        ),
        children: <Widget>[
          // 1. Estado: Carregamento / Processamento (ProgressCard)
          if (state.isLoading) ...<Widget>[
            ProgressCard(
              state: state.step == ScannerStep.uploading
                  ? ProgressCardState.uploading
                  : ProgressCardState.analyzing,
              title: state.statusText,
              progress: state.uploadProgress,
              description: state.step == ScannerStep.uploading
                  ? 'Transferindo binário para verificação na nuvem do VirusTotal...'
                  : 'Processando assinaturas criptográficas com motores de proteção...',
            ),
          ]

          // 2. Estado: Solicitação de Consentimento para Upload (PermissionDialog)
          else if (state.step == ScannerStep.promptConsent) ...<Widget>[
            PermissionDialog(
              type: PermissionDialogType.upload,
              title: 'Arquivo Não Catalogado',
              body:
                  'Nenhum relatório foi encontrado para o hash deste arquivo no VirusTotal.\n\n'
                  'Deseja enviar "${state.selectedFile?.name}" (${state.selectedFile?.formattedSize}) '
                  'para verificação remota pelos motores antivírus?\n\n'
                  'O arquivo poderá ser processado de acordo com as políticas do VirusTotal.',
              confirmLabel: 'Enviar Arquivo',
              cancelLabel: 'Cancelar',
              onConfirm: notifier.confirmUpload,
              onCancel: notifier.cancelConsent,
            ),
          ]

          // 3. Estado: Erro
          else if (state.step == ScannerStep.error) ...<Widget>[
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: AppShapes.borderLarge,
                border: Border.all(color: colors.danger, width: AppShapes.borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.error_outline, color: colors.danger, size: 24),
                      const SizedBox(width: AppSpacing.space8),
                      Text(
                        'Atenção',
                        style: AppTypography.cardTitle.copyWith(color: colors.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Text(
                    state.errorMessage ?? 'Ocorreu um erro durante a operação.',
                    style: AppTypography.body.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  FileGuardButton(
                    label: 'Tentar Novamente',
                    icon: Icons.refresh_rounded,
                    onPressed: notifier.reset,
                  ),
                ],
              ),
            ),
          ]

          // 3b. Estado: Enfileirado no VirusTotal (Aguardando conclusão assíncrona)
          else if (state.step == ScannerStep.queued) ...<Widget>[
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: AppShapes.borderLarge,
                border: Border.all(color: colors.neutral, width: AppShapes.borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.hourglass_top_rounded, color: colors.neutral, size: 24),
                      const SizedBox(width: AppSpacing.space8),
                      Text(
                        'Análise em processamento',
                        style: AppTypography.cardTitle.copyWith(color: colors.neutral),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Text(
                    'O arquivo "${state.selectedFile?.name ?? 'enviado'}" foi transmitido com sucesso e está na fila dos motores antivírus do VirusTotal.',
                    style: AppTypography.body.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  FileGuardButton(
                    label: 'Verificar status agora',
                    icon: Icons.refresh_rounded,
                    onPressed: notifier.recheckPendingAnalysis,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  OutlinedButton(
                    onPressed: notifier.reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(borderRadius: AppShapes.borderMedium),
                    ),
                    child: Text(
                      'Voltar ao início',
                      style: AppTypography.bodyCompact.copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ]

          // 4. Estado: Concluído (Relatório da Análise - Tela 51 Figma)
          else if (state.step == ScannerStep.completed && state.report != null) ...<Widget>[
            _buildReportView(context, state.report!, state.selectedFile, notifier),
          ]

          // 5. Estado Inicial (Idle)
          else ...<Widget>[
            _buildIdleView(context, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildIdleView(BuildContext context, ScannerNotifier notifier) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Text(
                      'Análise Rápida de Arquivos',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                'Selecione qualquer arquivo ou APK do seu aparelho para verificar sua integridade contra mais de 70 motores antivírus simultaneamente.',
                style: AppTypography.body.copyWith(
                  color: colors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.space20),
              FileGuardButton(
                label: 'Selecionar Arquivo',
                icon: Icons.file_open_outlined,
                onPressed: notifier.pickAndScan,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        Container(
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
            children: <Widget>[
              Text(
                'Como funciona o fluxo de segurança:',
                style: AppTypography.subheading.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                '1. O hash SHA-256 é calculado localmente no seu dispositivo.\n'
                '2. Apenas a assinatura (hash) é consultada no VirusTotal primeiro.\n'
                '3. Se o arquivo já tiver sido catalogado, o relatório é exibido imediatamente.\n'
                '4. Se nunca foi analisado, você escolhe se autoriza o envio do arquivo original.',
                style: AppTypography.caption.copyWith(
                  color: colors.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportView(
    BuildContext context,
    ScanReport report,
    dynamic selectedFile,
    ScannerNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;
    final isDark = theme.brightness == Brightness.dark;
    final isApk = report.fileName.toLowerCase().endsWith('.apk');

    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedTextColor =
        isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final previewEngines = _selectPreviewEngines(report);
    final totalEnginesCount = report.results.isNotEmpty
        ? report.results.length
        : report.stats.totalEngines;

    final formattedUtcDate =
        DateFormat("dd/MM/yyyy · HH:mm 'UTC'").format(report.scanDate.toUtc());
    final analysisDateStr = DateFormat('dd/MM/yyyy').format(report.scanDate.toUtc());
    final analysisTimeStr = DateFormat("HH:mm 'UTC'").format(report.scanDate.toUtc());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 1. Resumo da Análise (ReportSummaryCard - Figma 6:7773 / 6:7944)
        ReportSummaryCard.fromReport(report),
        const SizedBox(height: AppSpacing.space12),

        // 2. Contexto do Relatório (Figma 6:7778 / 6:7949)
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
                report.fileName,
                style: AppTypography.subheading.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                formattedUtcDate,
                style: AppTypography.caption.copyWith(
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 3. Informações do Arquivo (Figma 6:7797 / 6:7968)
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
                'Informações do arquivo',
                style: AppTypography.cardTitle.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              _buildInfoRow('Nome do arquivo', report.fileName, primaryTextColor, mutedTextColor),
              _buildInfoRow(
                'Tipo / tamanho',
                '${_resolveFileType(report)} · ${FileSizeFormatter.format(report.fileSize)}',
                primaryTextColor,
                mutedTextColor,
              ),
              _buildInfoRow(
                'Data da análise',
                '$analysisDateStr\n$analysisTimeStr',
                primaryTextColor,
                mutedTextColor,
              ),
              _buildInfoRow(
                'Origem do relatório',
                'VirusTotal API v3',
                primaryTextColor,
                mutedTextColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 4. Prévia dos Mecanismos de Segurança (Figma 6:7784 / 6:7955)
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
                'Mecanismos de segurança',
                style: AppTypography.cardTitle.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'MECANISMO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'RESULTADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (previewEngines.isEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
                  child: Text(
                    'Nenhum mecanismo detalhado disponível nesta análise.',
                    style: AppTypography.caption.copyWith(color: mutedTextColor),
                  ),
                ),
              ] else ...<Widget>[
                ...previewEngines.map((engine) {
                  final (resultText, resultColor) =
                      _resolvePreviewEngineDisplay(engine, colors);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            engine.engineName,
                            style: AppTypography.bodyCompact.copyWith(
                              color: mutedTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          resultText,
                          style: AppTypography.bodyCompact.copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: AppSpacing.space12),
              FileGuardButton(
                label: 'Ver os $totalEnginesCount mecanismos',
                style: FileGuardButtonStyle.tonal,
                onPressed: () => context.push(
                  AppRoutes.technicalDetails,
                  extra: report,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 5. Card SHA-256 Copiável (Figma 6:7811 / 6:7982)
        Container(
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
                'SHA-256',
                style: AppTypography.caption.copyWith(
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              SelectableText(
                report.sha256,
                style: AppTypography.technical.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Semantics(
                button: true,
                label: 'Copiar impressão digital SHA-256',
                child: InkWell(
                  borderRadius: AppShapes.borderSmall,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: report.sha256));
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hash SHA-256 copiado para a área de transferência.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                    child: Text(
                      'Copiar impressão digital',
                      style: AppTypography.bodyCompact.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 6. Botão de Acesso a Detalhes Técnicos (Figma 6:7766)
        FileGuardButton(
          label: 'Detalhes técnicos',
          style: FileGuardButtonStyle.tonal,
          onPressed: () => context.push(
            AppRoutes.technicalDetails,
            extra: report,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 7. Botão Abrir no VirusTotal (Figma 6:7766)
        FileGuardButton(
          label: 'Abrir relatório no VirusTotal ↗',
          style: FileGuardButtonStyle.tonal,
          onPressed: () => _openVirusTotal(context, report),
        ),
        const SizedBox(height: AppSpacing.space12),

        // 8. Ações de Relatório: Compartilhar e Exportar (Figma 6:7781)
        Row(
          children: <Widget>[
            Expanded(
              child: FileGuardButton(
                label: 'Compartilhar',
                style: FileGuardButtonStyle.tonal,
                onPressed: () => _shareReport(report),
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: FileGuardButton(
                label: 'Exportar',
                style: FileGuardButtonStyle.tonal,
                onPressed: () => _exportReport(context, report),
              ),
            ),
          ],
        ),

        // 9. Seção Especial para APKs (Instalação opcional)
        if (isApk && selectedFile?.path != null && (selectedFile.path as String).isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space16),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppShapes.borderLarge,
              border: Border.all(
                color: report.stats.malicious > 0 ? colors.danger : colors.neutral,
                width: AppShapes.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      report.stats.malicious > 0
                          ? Icons.warning_amber_rounded
                          : Icons.android_rounded,
                      color: report.stats.malicious > 0 ? colors.danger : colors.neutral,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'Gerenciamento do Pacote APK',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  report.stats.malicious > 0
                      ? 'ATENÇÃO: Este pacote possui detecções ativas de malware. A instalação pode comprometer a segurança do seu aparelho.'
                      : 'Nenhuma ameaça conhecida foi reportada pelos motores para este APK.',
                  style: AppTypography.caption.copyWith(
                    color: report.stats.malicious > 0 ? colors.danger : mutedTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                FileGuardButton(
                  label: 'Encaminhar ao Instalador Android',
                  icon: Icons.install_mobile_rounded,
                  style: report.stats.malicious > 0
                      ? FileGuardButtonStyle.danger
                      : FileGuardButtonStyle.filled,
                  onPressed: () async {
                    final success = await const ApkInstallService().installApk(selectedFile.path as String);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Falha ao abrir o instalador do sistema.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space16),

        // 10. Aviso Legal / Disclaimer (Figma 6:7817 / 6:7988)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Text(
            'Os resultados refletem o relatório na data indicada, não uma proteção contínua do dispositivo.',
            style: AppTypography.caption.copyWith(
              color: mutedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.space20),

        // 11. Escanear Outro Arquivo
        FileGuardButton(
          label: 'Escanear Outro Arquivo',
          icon: Icons.refresh_rounded,
          onPressed: notifier.reset,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color primaryColor,
    Color mutedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: AppTypography.bodyCompact.copyWith(
                color: mutedColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
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
}
