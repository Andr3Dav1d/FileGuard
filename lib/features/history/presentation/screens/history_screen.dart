import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/widgets/detection_badge.dart';
import 'package:fileguard/core/widgets/file_guard_button.dart';
import 'package:fileguard/core/widgets/file_list_tile.dart';
import 'package:fileguard/core/widgets/statistic_card.dart';
import 'package:fileguard/features/history/data/services/backup_service.dart';
import 'package:fileguard/features/history/presentation/providers/history_provider.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';

/// Tela de Histórico de Análises com suporte a detalhes, exclusão e backup local.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  DetectionBadgeStatus _verdictToBadgeStatus(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.malicious:
        return DetectionBadgeStatus.malicious;
      case ScanVerdict.suspicious:
        return DetectionBadgeStatus.suspicious;
      case ScanVerdict.noDetections:
        return DetectionBadgeStatus.noDetections;
      case ScanVerdict.inconclusive:
        return DetectionBadgeStatus.inconclusive;
      case ScanVerdict.pending:
        return DetectionBadgeStatus.pending;
    }
  }

  void _showReportDetails(BuildContext context, WidgetRef ref, ScanReport report) {
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);
    final badgeStatus = _verdictToBadgeStatus(report.verdict);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(report.scanDate);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppShapes.radiusExtraLarge)),
      ),
      builder: (ctx) {
        return Padding(
          padding: AppSpacing.dialogPadding.copyWith(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  DetectionBadge(status: badgeStatus),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                report.fileName,
                style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Analisado em: $formattedDate · ${(report.fileSize / 1024).toStringAsFixed(1)} KB',
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                'SHA-256:',
                style: AppTypography.micro.copyWith(color: colors.muted),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      report.sha256,
                      style: AppTypography.technical.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copiar Hash',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: report.sha256));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hash copiado para a área de transferência!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatisticCard(
                      type: StatisticCardType.total,
                      value: report.stats.totalEngines.toString(),
                      label: 'Motores',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: StatisticCard(
                      type: StatisticCardType.malicious,
                      value: report.stats.malicious.toString(),
                      label: 'Ameaças',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: StatisticCard(
                      type: StatisticCardType.suspicious,
                      value: report.stats.suspicious.toString(),
                      label: 'Suspeitos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FileGuardButton(
                      label: 'Compartilhar',
                      icon: Icons.share_outlined,
                      style: FileGuardButtonStyle.tonal,
                      onPressed: () {
                        final shareText = 'Relatório FileGuard:\n'
                            'Arquivo: ${report.fileName}\n'
                            'SHA-256: ${report.sha256}\n'
                            'Detecções: ${report.stats.malicious}/${report.stats.totalEngines}\n'
                            'Link: ${report.permalink ?? "N/A"}';
                        SharePlus.instance.share(ShareParams(text: shareText));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: FileGuardButton(
                      label: 'Excluir',
                      icon: Icons.delete_outline,
                      style: FileGuardButtonStyle.danger,
                      onPressed: () async {
                        await ref.read(historyNotifierProvider.notifier).deleteReport(report.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: const Text(
          'Esta ação removerá todos os registros de análises armazenados localmente no dispositivo.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar Tudo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyNotifierProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Histórico limpo com sucesso!')),
        );
      }
    }
  }

  Future<void> _handleExportBackup(BuildContext context, List<ScanReport> reports) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há registros para exportar no momento.')),
      );
      return;
    }

    const backupService = BackupService();
    final jsonBackup = backupService.exportToJson(reports);
    await SharePlus.instance.share(
      ShareParams(
        text: jsonBackup,
        subject: 'fileguard_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: <Widget>[
          historyAsync.maybeWhen(
            data: (reports) => reports.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      if (action == 'export') {
                        _handleExportBackup(context, reports);
                      } else if (action == 'clear') {
                        _handleClearAll(context, ref);
                      }
                    },
                    itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'export',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.download_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Exportar Backup (JSON)'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'clear',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Limpar Histórico', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              'Erro ao carregar histórico: $err',
              style: AppTypography.body.copyWith(color: colors.danger),
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.history_toggle_off_rounded, size: 64, color: colors.muted),
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      'Nenhuma análise registrada',
                      style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Quando você verificar arquivos ou pacotes APK no Analisador, os relatórios ficarão salvos aqui offline.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.space16,
              bottom: AppSpacing.space40,
            ),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.space8),
            itemBuilder: (context, index) {
              final report = reports[index];
              final isThreat = report.stats.malicious > 0;
              final isSuspicious = report.stats.suspicious > 0;
              final statusColor = isThreat
                  ? colors.danger
                  : isSuspicious
                      ? colors.warning
                      : colors.neutral;

              final statusText = isThreat
                  ? 'Ameaça · ${report.stats.malicious}/${report.stats.totalEngines}'
                  : isSuspicious
                      ? 'Suspeito · ${report.stats.suspicious}/${report.stats.totalEngines}'
                      : 'Sem detecções · 0/${report.stats.totalEngines}';

              final dateStr = DateFormat('dd/MM HH:mm').format(report.scanDate);
              final sizeStr = '${(report.fileSize / 1024).toStringAsFixed(1)} KB';

              return FileListTile(
                name: report.fileName,
                detail: '$sizeStr · $dateStr',
                status: statusText,
                statusColor: statusColor,
                icon: report.fileName.toLowerCase().endsWith('.apk')
                    ? Icons.android_rounded
                    : Icons.insert_drive_file_outlined,
                onTap: () => _showReportDetails(context, ref, report),
              );
            },
          );
        },
      ),
    );
  }
}
