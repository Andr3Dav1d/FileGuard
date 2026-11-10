import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';

/// Botão de Ação Flutuante (FAB) do analisador conforme nó 6:532 do Figma.
///
/// Apresenta cantos arredondados de 16 dp, fundo `primaryContainer` e modelo planar sem elevação.
class ScanFAB extends StatelessWidget {
  const ScanFAB({
    super.key,
    required this.onPressed,
    this.tooltip = 'Analisar arquivo',
  });

  /// Callback de clique do botão.
  final VoidCallback? onPressed;

  /// Texto de acessibilidade e tooltip.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: AppShapes.borderExtraLarge,
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: AppShapes.borderExtraLarge,
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 56.0,
            height: 56.0,
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Icon(
              Icons.filter_center_focus,
              size: 24.0,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
