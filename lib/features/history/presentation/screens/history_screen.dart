import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/utils/file_size_formatter.dart';
import 'package:fileguard/core/widgets/file_guard_app_bar.dart';
import 'package:fileguard/core/widgets/file_list_tile.dart';
import 'package:fileguard/features/history/data/services/backup_service.dart';
import 'package:fileguard/features/history/presentation/providers/history_provider.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';

/// Tela de Histórico de Análises com suporte a detalhes completos, exclusão e backup local.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

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

  Future<void> _handleImportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) return;
      final content = await file.xFile.readAsString();
      if (content.trim().isEmpty) return;

      const backupService = BackupService();
      final reports = backupService.importFromJson(content);
      if (reports.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum relatório encontrado no arquivo de backup.')),
          );
        }
        return;
      }

      final notifier = ref.read(historyNotifierProvider.notifier);
      final count = await notifier.importReports(reports);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count relatório(s) restaurado(s) com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao importar backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: FileGuardAppBar(
        title: 'Histórico',
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == 'export') {
                historyAsync.whenData((reports) => _handleExportBackup(context, reports));
              } else if (action == 'import') {
                _handleImportBackup(context, ref);
              } else if (action == 'clear') {
                _handleClearAll(context, ref);
              }
            },
            itemBuilder: (ctx) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.upload_file_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Restaurar Backup (JSON)'),
                  ],
                ),
              ),
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

              final dateStr = report.scanDate.millisecondsSinceEpoch <= 0
                  ? 'Data desconhecida'
                  : DateFormat('dd/MM HH:mm').format(report.scanDate);
              final sizeStr = FileSizeFormatter.format(report.fileSize);

              return Dismissible(
                key: Key(report.id.isNotEmpty ? report.id : report.sha256),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: colors.danger,
                    borderRadius: AppShapes.borderMedium,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir registro?'),
                      content: Text('Deseja remover "${report.fileName}" do histórico?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref.read(historyNotifierProvider.notifier).deleteReport(report.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${report.fileName}" removido do histórico.')),
                  );
                },
                child: FileListTile(
                  name: report.fileName,
                  detail: '$sizeStr · $dateStr',
                  status: statusText,
                  statusColor: statusColor,
                  icon: report.fileName.toLowerCase().endsWith('.apk')
                      ? Icons.android_rounded
                      : Icons.insert_drive_file_outlined,
                  onTap: () {
                    context.push(
                      AppRoutes.technicalDetails,
                      extra: report,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
