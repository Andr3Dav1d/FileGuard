import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';

/// Item de lista para exibição de arquivos analisados conforme Seção 8 do Design System.
///
/// Apresenta ícone com contêiner destacado, nome do arquivo, metadados, status de risco e
/// indicador de navegação.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.name,
    required this.detail,
    required this.status,
    this.statusColor,
    this.icon = Icons.insert_drive_file_outlined,
    this.onTap,
  });

  /// Nome do arquivo (14px Medium).
  final String name;

  /// Metadados (ex.: "APK · 7,4 MB · Hoje, 09:41").
  final String detail;

  /// Texto do status de detecção (ex.: "Nenhuma detecção · 0 / 70" ou "Malicioso · 12 / 70").
  final String status;

  /// Cor opcional para o status. Se nula, utiliza a cor neutra/segura por padrão.
  final Color? statusColor;

  /// Ícone representativo do tipo de arquivo.
  final IconData icon;

  /// Callback de toque.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    final resolvedStatusColor = statusColor ?? colors.neutral;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.space8),
      child: Row(
        children: <Widget>[
          // Contêiner de ícone destacado (48 × 48 dp, raio 16 dp)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppShapes.borderExtraLarge,
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          // Informações do arquivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  style: AppTypography.bodyCompact.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  detail,
                  style: AppTypography.caption.copyWith(
                    color: colors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: resolvedStatusColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Icon(
            Icons.chevron_right,
            size: 24,
            color: colors.muted,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppShapes.borderMedium,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
