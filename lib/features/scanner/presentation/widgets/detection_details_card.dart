import 'package:flutter/material.dart';

import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'engine_report_table.dart';

/// Card expansível de detalhes de detecção conforme componente Figma `6:2980`
/// (estados Collapsed `6:563` e Expanded `6:2961`).
///
/// Possui animação fluida no chevron e no corpo do card, embute o [EngineReportTable]
/// quando expandido e mantém acessibilidade com área de toque mínima de 48dp.
class DetectionDetailsCard extends StatefulWidget {
  const DetectionDetailsCard({
    super.key,
    required this.results,
    this.initialExpanded = false,
    this.title = 'Detalhes da detecção',
    this.onExpansionChanged,
  });

  /// Resultados de cada motor antivírus.
  final Map<String, EngineResult> results;

  /// Estado inicial de expansão.
  final bool initialExpanded;

  /// Título do card no cabeçalho.
  final String title;

  /// Callback opcional notificado ao alternar expansão.
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<DetectionDetailsCard> createState() => _DetectionDetailsCardState();
}

class _DetectionDetailsCardState extends State<DetectionDetailsCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _chevronTurns;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _chevronTurns = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.5).chain(
        CurveTween(curve: Curves.easeInOutCubic),
      ),
    );
    _expandAnimation = _controller.drive(
      CurveTween(curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  String _buildSubtitle() {
    final threatCount = widget.results.values
        .where((e) => e.isMalicious || e.isSuspicious)
        .length;
    final totalCount = widget.results.length;

    if (threatCount > 0) {
      return _isExpanded
          ? '$threatCount mecanismos sinalizaram ameaças ou suspeitas neste arquivo.'
          : '$threatCount mecanismos sinalizaram este arquivo. Toque para ver a lista completa.';
    }

    if (totalCount > 0) {
      return _isExpanded
          ? 'Nenhum dos $totalCount mecanismos catalogados reportou ameaças.'
          : 'Nenhum mecanismo detectou ameaças. Toque para ver todos os $totalCount mecanismos.';
    }

    return 'Nenhum dado de mecanismo disponível para este relatório.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Semantics(
      expanded: _isExpanded,
      button: true,
      label: widget.title,
      hint: _isExpanded ? 'Toque para recolher' : 'Toque para expandir',
      child: Container(
        width: double.infinity,
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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Cabeçalho interativo tocável com alvo de toque adequado
            InkWell(
              onTap: _toggleExpansion,
              borderRadius: AppShapes.borderLarge,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppTypography.subheading.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        RotationTransition(
                          turns: _chevronTurns,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 24,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      _buildSubtitle(),
                      style: AppTypography.body.copyWith(
                        color: colors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Corpo expansível animado contendo a tabela de motores
            SizeTransition(
              sizeFactor: _expandAnimation,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.space16,
                  right: AppSpacing.space16,
                  bottom: AppSpacing.space16,
                ),
                child: EngineReportTable(
                  results: widget.results,
                  title: '', // Sem duplicar o título dentro da expansão
                  showSearchAndFilters: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
