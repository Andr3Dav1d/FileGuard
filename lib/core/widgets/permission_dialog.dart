import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/file_guard_colors.dart';
import 'file_guard_button.dart';

/// Tipos de diálogo de permissão com foco em privacidade.
enum PermissionDialogType {
  upload,
  hashLookup,
}

/// Diálogo de permissão e consentimento explícito conforme Seção 6 e 8 do Design System.
///
/// Adota a especificação de tela com cantos arredondados de 28 dp e padding interno de 24 dp.
class PermissionDialog extends StatelessWidget {
  const PermissionDialog({
    super.key,
    required this.type,
    this.title,
    this.body,
    this.onCancel,
    this.onConfirm,
    this.cancelLabel = 'Cancelar',
    this.confirmLabel,
  });

  /// Tipo de solicitação de permissão.
  final PermissionDialogType type;

  /// Título customizado.
  final String? title;

  /// Texto do corpo explicativo sobre privacidade.
  final String? body;

  /// Callback de cancelamento.
  final VoidCallback? onCancel;

  /// Callback de confirmação.
  final VoidCallback? onConfirm;

  /// Rótulo do botão de cancelamento.
  final String cancelLabel;

  /// Rótulo do botão de confirmação.
  final String? confirmLabel;

  /// Exibe o diálogo na tela com o tema e scrim corretos.
  static Future<bool?> show({
    required BuildContext context,
    required PermissionDialogType type,
    String? title,
    String? body,
    String? cancelLabel,
    String? confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: context.fileGuardColors.modalScrim,
      builder: (dialogContext) {
        return PermissionDialog(
          type: type,
          title: title,
          body: body,
          cancelLabel: cancelLabel ?? 'Cancelar',
          confirmLabel: confirmLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
  }

  String _defaultTitle() {
    switch (type) {
      case PermissionDialogType.upload:
        return 'Enviar este arquivo?';
      case PermissionDialogType.hashLookup:
        return 'Consultar hash SHA-256?';
    }
  }

  String _defaultBody() {
    switch (type) {
      case PermissionDialogType.upload:
        return 'O arquivo original será enviado ao VirusTotal. As amostras podem ser compartilhadas com parceiros de segurança. Evite arquivos pessoais ou confidenciais.';
      case PermissionDialogType.hashLookup:
        return 'Apenas a impressão digital criptográfica (hash SHA-256) será enviada para verificar se o arquivo já foi analisado anteriormente. Seu arquivo permanece no dispositivo.';
    }
  }

  String _defaultConfirmLabel() {
    switch (type) {
      case PermissionDialogType.upload:
        return 'Enviar arquivo';
      case PermissionDialogType.hashLookup:
        return 'Consultar hash';
    }
  }

  IconData _icon() {
    switch (type) {
      case PermissionDialogType.upload:
        return Icons.cloud_upload_outlined;
      case PermissionDialogType.hashLookup:
        return Icons.fingerprint_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    final resolvedTitle = title ?? _defaultTitle();
    final resolvedBody = body ?? _defaultBody();
    final resolvedConfirmLabel = confirmLabel ?? _defaultConfirmLabel();

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.borderDialog,
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: AppShapes.borderWidth,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: AppSpacing.space24,
      ),
      child: Padding(
        padding: AppSpacing.dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              _icon(),
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              resolvedTitle,
              style: AppTypography.dialogTitle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              resolvedBody,
              style: AppTypography.body.copyWith(
                color: colors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            FileGuardButton(
              label: cancelLabel,
              style: FileGuardButtonStyle.tonal,
              onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.space12),
            FileGuardButton(
              label: resolvedConfirmLabel,
              style: FileGuardButtonStyle.filled,
              onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
