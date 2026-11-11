import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/file_guard_colors.dart';
import '../../../../core/widgets/file_guard_button.dart';
import '../../../../core/widgets/file_list_tile.dart';
import '../../../../core/widgets/statistic_card.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/api_key_provider.dart';

/// Tela inicial (Início) - Dashboard utilitário com resumo de segurança e ações rápidas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fileGuardColors;
    final theme = Theme.of(context);
    final historyAsync = ref.watch(historyNotifierProvider);
    final apiKeyState = ref.watch(apiKeyNotifierProvider);

    final reports = historyAsync.asData?.value ?? [];
    final totalScans = reports.length;
    final totalThreats = reports.where((r) => r.stats.malicious > 0).length;
    final totalSuspicious = reports.where((r) => r.stats.suspicious > 0 && r.stats.malicious == 0).length;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.shield_outlined),
        title: const Text('FileGuard'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.space16,
          bottom: AppSpacing.space40,
        ),
        children: <Widget>[
          // 1. Status de Prontidão da Chave
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppShapes.borderLarge,
              border: Border.all(
                color: apiKeyState.hasKey ? colors.neutral : colors.warning,
                width: AppShapes.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      apiKeyState.hasKey ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: apiKeyState.hasKey ? colors.neutral : colors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        apiKeyState.hasKey
                            ? 'Proteção Operacional'
                            : 'API Key Não Configurada',
                        style: AppTypography.cardTitle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  apiKeyState.hasKey
                      ? 'Conexão ativa com a API do VirusTotal.'
                      : 'Configure sua chave pessoal nas configurações para realizar consultas aos motores antivírus.',
                  style: AppTypography.caption.copyWith(color: colors.muted),
                ),
                if (!apiKeyState.hasKey) ...<Widget>[
                  const SizedBox(height: AppSpacing.space8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
                      ),
                      onPressed: () => context.go(AppRoutes.settings),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Configurar'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space20),

          // 2. Resumo Numérico
          Text(
            'Visão Geral',
            style: AppTypography.subheading.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: <Widget>[
              Expanded(
                child: StatisticCard(
                  type: StatisticCardType.total,
                  value: totalScans.toString(),
                  label: 'Análises',
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: StatisticCard(
                  type: StatisticCardType.malicious,
                  value: totalThreats.toString(),
                  label: 'Ameaças',
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: StatisticCard(
                  type: StatisticCardType.suspicious,
                  value: totalSuspicious.toString(),
                  label: 'Suspeitos',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space24),

          // 3. Ação Rápida
          FileGuardButton(
            label: 'Analisar Arquivo',
            icon: Icons.upload_file_outlined,
            onPressed: () => context.go(AppRoutes.scanner),
          ),

          const SizedBox(height: AppSpacing.space24),

          // 4. Últimas Análises
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Análises Recentes',
                style: AppTypography.subheading.copyWith(color: theme.colorScheme.onSurface),
              ),
              if (reports.isNotEmpty)
                TextButton(
                  onPressed: () => context.go(AppRoutes.history),
                  child: const Text('Ver todas'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),

          if (reports.isEmpty)
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: AppShapes.borderLarge,
                border: Border.all(color: theme.colorScheme.outline, width: AppShapes.borderWidth),
              ),
              child: Text(
                'Nenhum arquivo analisado recentemente. Toque no botão acima para iniciar sua primeira verificação.',
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
            )
          else
            ...reports.take(3).map((r) {
              final isThreat = r.stats.malicious > 0;
              final isSuspicious = r.stats.suspicious > 0;
              final statusColor = isThreat
                  ? colors.danger
                  : isSuspicious
                      ? colors.warning
                      : colors.neutral;

              final statusText = isThreat
                  ? 'Ameaça · ${r.stats.malicious}/${r.stats.totalEngines}'
                  : isSuspicious
                      ? 'Suspeito · ${r.stats.suspicious}/${r.stats.totalEngines}'
                      : 'Sem detecções · 0/${r.stats.totalEngines}';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: FileListTile(
                  name: r.fileName,
                  detail: '${(r.fileSize / 1024).toStringAsFixed(1)} KB · ${DateFormat('dd/MM HH:mm').format(r.scanDate)}',
                  status: statusText,
                  statusColor: statusColor,
                  icon: r.fileName.toLowerCase().endsWith('.apk')
                      ? Icons.android_rounded
                      : Icons.insert_drive_file_outlined,
                  onTap: () => context.go(AppRoutes.history),
                ),
              );
            }),
        ],
      ),
    );
  }
}
