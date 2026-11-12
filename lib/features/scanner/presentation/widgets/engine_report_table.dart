import 'package:flutter/material.dart';

import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';

/// Filtros de categoria suportados na [EngineReportTable].
enum EngineFilterCategory {
  all,
  malicious,
  suspicious,
  undetected,
  harmless,
  timeout,
  failure,
  typeUnsupported,
  unknown;

  String label(int count) {
    switch (this) {
      case EngineFilterCategory.all:
        return 'Todos ($count)';
      case EngineFilterCategory.malicious:
        return 'Maliciosos ($count)';
      case EngineFilterCategory.suspicious:
        return 'Suspeitos ($count)';
      case EngineFilterCategory.undetected:
        return 'Sem detecção ($count)';
      case EngineFilterCategory.harmless:
        return 'Inofensivos ($count)';
      case EngineFilterCategory.timeout:
        return 'Timeout ($count)';
      case EngineFilterCategory.failure:
        return 'Falha ($count)';
      case EngineFilterCategory.typeUnsupported:
        return 'Não suportado ($count)';
      case EngineFilterCategory.unknown:
        return 'Desconhecido ($count)';
    }
  }
}

/// Tabela detalhada de mecanismos antivírus conforme componente Figma `6:549`.
///
/// Apresenta colunas MECANISMO e RESULTADO, barra de pesquisa textual,
/// chips de filtro por categoria semântica e estado vazio.
class EngineReportTable extends StatefulWidget {
  const EngineReportTable({
    super.key,
    required this.results,
    this.title = 'Mecanismos de segurança',
    this.showSearchAndFilters = true,
  });

  /// Resultados dos motores antivírus indexados pelo nome do motor.
  final Map<String, EngineResult> results;

  /// Título opcional da tabela.
  final String title;

  /// Se deve exibir a barra de busca e filtros de categoria.
  final bool showSearchAndFilters;

  @override
  State<EngineReportTable> createState() => _EngineReportTableState();
}

class _EngineReportTableState extends State<EngineReportTable> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  EngineFilterCategory _selectedCategory = EngineFilterCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Map<EngineFilterCategory, int> _calculateCounts(List<EngineResult> list) {
    final Map<EngineFilterCategory, int> counts = {
      for (final cat in EngineFilterCategory.values) cat: 0,
    };
    counts[EngineFilterCategory.all] = list.length;

    for (final engine in list) {
      switch (engine.engineCategory) {
        case EngineCategory.malicious:
          counts[EngineFilterCategory.malicious] =
              (counts[EngineFilterCategory.malicious] ?? 0) + 1;
          break;
        case EngineCategory.suspicious:
          counts[EngineFilterCategory.suspicious] =
              (counts[EngineFilterCategory.suspicious] ?? 0) + 1;
          break;
        case EngineCategory.undetected:
          counts[EngineFilterCategory.undetected] =
              (counts[EngineFilterCategory.undetected] ?? 0) + 1;
          break;
        case EngineCategory.harmless:
          counts[EngineFilterCategory.harmless] =
              (counts[EngineFilterCategory.harmless] ?? 0) + 1;
          break;
        case EngineCategory.timeout:
          counts[EngineFilterCategory.timeout] =
              (counts[EngineFilterCategory.timeout] ?? 0) + 1;
          break;
        case EngineCategory.failure:
          counts[EngineFilterCategory.failure] =
              (counts[EngineFilterCategory.failure] ?? 0) + 1;
          break;
        case EngineCategory.typeUnsupported:
          counts[EngineFilterCategory.typeUnsupported] =
              (counts[EngineFilterCategory.typeUnsupported] ?? 0) + 1;
          break;
        case EngineCategory.unknown:
          counts[EngineFilterCategory.unknown] =
              (counts[EngineFilterCategory.unknown] ?? 0) + 1;
          break;
      }
    }
    return counts;
  }

  List<EngineResult> _filterEngines(List<EngineResult> rawList) {
    return rawList.where((engine) {
      // 1. Filtro textual
      if (_searchQuery.isNotEmpty) {
        final nameMatch = engine.engineName.toLowerCase().contains(_searchQuery);
        final resultMatch = engine.result?.toLowerCase().contains(_searchQuery) ?? false;
        if (!nameMatch && !resultMatch) {
          return false;
        }
      }

      // 2. Filtro por categoria
      switch (_selectedCategory) {
        case EngineFilterCategory.all:
          return true;
        case EngineFilterCategory.malicious:
          return engine.isMalicious;
        case EngineFilterCategory.suspicious:
          return engine.isSuspicious;
        case EngineFilterCategory.undetected:
          return engine.isUndetected;
        case EngineFilterCategory.harmless:
          return engine.isHarmless;
        case EngineFilterCategory.timeout:
          return engine.isTimeout;
        case EngineFilterCategory.failure:
          return engine.isFailure;
        case EngineFilterCategory.typeUnsupported:
          return engine.isTypeUnsupported;
        case EngineFilterCategory.unknown:
          return engine.engineCategory == EngineCategory.unknown;
      }
    }).toList();
  }

  (String, Color, FontWeight) _resolveEngineDisplay(
    EngineResult engine,
    FileGuardColors colors,
  ) {
    switch (engine.engineCategory) {
      case EngineCategory.malicious:
        return (
          engine.result ?? 'Malicioso',
          colors.danger,
          FontWeight.w500,
        );
      case EngineCategory.suspicious:
        return (
          engine.result ?? 'Suspeito',
          colors.warning,
          FontWeight.w500,
        );
      case EngineCategory.undetected:
        return (
          'Nenhuma detecção',
          colors.neutral,
          FontWeight.w400,
        );
      case EngineCategory.harmless:
        return (
          'Inofensivo',
          colors.neutral,
          FontWeight.w400,
        );
      case EngineCategory.timeout:
        return (
          'Tempo limite',
          colors.muted,
          FontWeight.w400,
        );
      case EngineCategory.failure:
        return (
          'Falha',
          colors.muted,
          FontWeight.w400,
        );
      case EngineCategory.typeUnsupported:
        return (
          'Não suportado',
          colors.muted,
          FontWeight.w400,
        );
      case EngineCategory.unknown:
        return (
          engine.result ?? engine.category,
          colors.muted,
          FontWeight.w400,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;
    final isDark = theme.brightness == Brightness.dark;

    final allEngines = widget.results.values.toList();
    final counts = _calculateCounts(allEngines);
    final filteredEngines = _filterEngines(allEngines);

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Título da seção
          if (widget.title.isNotEmpty) ...<Widget>[
            Text(
              widget.title,
              style: AppTypography.cardTitle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
          ],

          // Barra de pesquisa e chips de filtro
          if (widget.showSearchAndFilters && allEngines.isNotEmpty) ...<Widget>[
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTypography.body.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar mecanismo ou resultado...',
                hintStyle: AppTypography.body.copyWith(color: colors.muted),
                prefixIcon: Icon(Icons.search, size: 20, color: colors.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space8,
                ),
                filled: true,
                fillColor: colors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: AppShapes.borderMedium,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // Chips horizontais de filtro por categoria
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EngineFilterCategory.values
                    .where((cat) => (counts[cat] ?? 0) > 0 || cat == EngineFilterCategory.all)
                    .map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final count = counts[cat] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat.label(count)),
                      labelStyle: AppTypography.caption.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: colors.surfaceHigh,
                      checkmarkColor: theme.colorScheme.onPrimary,
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: AppShapes.borderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppShapes.borderSmall,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
          ],

          // Cabeçalho da Tabela: MECANISMO | RESULTADO
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: AppShapes.borderMedium,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'MECANISMO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RESULTADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),

          // Lista de Mecanismos ou Estado Vazio
          if (filteredEngines.isEmpty) ...<Widget>[
            Container(
              width: double.infinity,
              padding: AppSpacing.dialogPadding,
              decoration: BoxDecoration(
                color: colors.surfaceHigh,
                borderRadius: AppShapes.borderMedium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.search_off_rounded, size: 36, color: colors.muted),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Nenhum mecanismo encontrado',
                    style: AppTypography.cardTitle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Nenhum resultado corresponde à pesquisa ou filtro selecionado.',
                    style: AppTypography.caption.copyWith(color: colors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredEngines.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space8),
              itemBuilder: (context, index) {
                final engine = filteredEngines[index];
                final (displayText, displayColor, displayWeight) =
                    _resolveEngineDisplay(engine, colors);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space12,
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceHigh,
                    borderRadius: AppShapes.borderMedium,
                  ),
                  child: Row(
                    children: <Widget>[
                      // Nome do mecanismo (13px Medium)
                      Expanded(
                        child: Text(
                          engine.engineName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),

                      // Diagnóstico / Resultado com cor semântica
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: displayWeight,
                            color: displayColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
