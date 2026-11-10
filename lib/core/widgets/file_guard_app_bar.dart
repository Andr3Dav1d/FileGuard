import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Top App Bar contextual e planar conforme Seção 8.3 do Design System.
///
/// Possui altura mínima de 64 dp, alvos de toque de 48 × 48 dp e elevação zero.
class FileGuardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FileGuardAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  /// Título exibido na barra (20px Medium).
  final String title;

  /// Widget personalizado à esquerda (ex.: ícone de escudo ou menu).
  final Widget? leading;

  /// Lista de ações contextuais à direita.
  final List<Widget>? actions;

  /// Se deve exibir o botão de voltar padrão com alvo de 48 × 48 dp.
  final bool showBackButton;

  /// Callback acionado ao tocar no botão de voltar.
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = Semantics(
        button: true,
        label: 'Voltar',
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onBackPressed ?? () => Navigator.maybePop(context),
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              size: 24,
            ),
          ),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            if (leadingWidget != null)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: SizedBox(
                  width: AppSpacing.minTouchTarget,
                  height: AppSpacing.minTouchTarget,
                  child: Center(child: leadingWidget),
                ),
              )
            else
              const SizedBox(width: AppSpacing.space8),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Text(
                title,
                style: AppTypography.appBarTitle.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.map((action) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    child: action,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
