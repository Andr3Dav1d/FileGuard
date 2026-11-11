import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/widgets/detection_badge.dart';
import 'package:fileguard/core/widgets/file_guard_button.dart';
import 'package:fileguard/core/widgets/permission_dialog.dart';
import 'package:fileguard/core/widgets/progress_card.dart';
import 'package:fileguard/core/widgets/scan_fab.dart';
import 'package:fileguard/core/widgets/statistic_card.dart';
import 'package:fileguard/features/scanner/data/services/apk_install_service.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/presentation/providers/scanner_provider.dart';

/// Tela principal do Analisador de Arquivos e APKs.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

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

  void _shareReport(ScanReport report) {
    final text = 'Relatório FileGuard VirusTotal:\n'
        'Arquivo: ${report.fileName}\n'
        'SHA-256: ${report.sha256}\n'
        'Detecções: ${report.stats.malicious} maliciosos / ${report.stats.suspicious} suspeitos\n'
        'Total de motores: ${report.stats.totalEngines}\n'
        'Veredito: ${report.verdict.name.toUpperCase()}\n'
        'Link: ${report.permalink ?? "N/A"}';
    SharePlus.instance.share(ShareParams(text: text, subject: 'Relatório de Análise - ${report.fileName}'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerNotifierProvider);
    final notifier = ref.read(scannerNotifierProvider.notifier);
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisador'),
        actions: <Widget>[
          if (state.step == ScannerStep.completed || state.step == ScannerStep.error)
            IconButton(
              icon: const Icon(Icons.refresh),
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
                    icon: Icons.refresh,
                    onPressed: notifier.reset,
                  ),
                ],
              ),
            ),
          ]

          // 4. Estado: Concluído (Relatório da Análise)
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
    final badgeStatus = _verdictToBadgeStatus(report.verdict);
    final isApk = report.fileName.toLowerCase().endsWith('.apk');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Status Badge & Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DetectionBadge(status: badgeStatus),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartilhar Relatório',
              onPressed: () => _shareReport(report),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space16),

        // Nome do Arquivo e Metadados
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
                report.fileName,
                style: AppTypography.cardTitle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Tamanho: ${(report.fileSize / 1024).toStringAsFixed(1)} KB',
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
                        const SnackBar(content: Text('Hash SHA-256 copiado!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space16),

        // Cartões de Estatísticas
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

        // Seção Especial para APKs
        if (isApk && selectedFile?.path != null && (selectedFile.path as String).isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space20),
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
                    color: report.stats.malicious > 0 ? colors.danger : colors.muted,
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

        const SizedBox(height: AppSpacing.space24),

        // Ações de Rodapé
        FileGuardButton(
          label: 'Escanear Outro Arquivo',
          icon: Icons.search_rounded,
          onPressed: notifier.reset,
        ),
      ],
    );
  }
}
