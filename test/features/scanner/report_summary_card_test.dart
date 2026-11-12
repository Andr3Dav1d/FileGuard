import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/presentation/widgets/report_summary_card.dart';

Widget _wrap(Widget child, {bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('ReportSummaryCard Tests', () {
    testWidgets('1. Renderiza veredito malicious com contagem correta e texto explicativo', (
      WidgetTester tester,
    ) async {
      const stats = AnalysisStats(
        malicious: 12,
        suspicious: 2,
        undetected: 50,
        harmless: 6,
      );

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.malicious,
            stats: stats,
          ),
        ),
      );

      // Título e Placar (12 + 2 = 14 detecções em 70 motores)
      expect(find.text('Ameaça detectada'), findsOneWidget);
      expect(find.text('14 / 70'), findsOneWidget);
      expect(
        find.text('mecanismos detectaram uma ameaça neste relatório'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Múltiplos mecanismos identificaram este arquivo como malicioso'),
        findsOneWidget,
      );
    });

    testWidgets('2. Renderiza veredito noDetections (sem interpretar como garantia absoluta)', (
      WidgetTester tester,
    ) async {
      const stats = AnalysisStats(
        malicious: 0,
        suspicious: 0,
        undetected: 68,
        harmless: 2,
      );

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.noDetections,
            stats: stats,
          ),
        ),
      );

      expect(find.text('Nenhuma detecção'), findsOneWidget);
      expect(find.text('0 / 70'), findsOneWidget);
      expect(
        find.text('Nenhum mecanismo detectou ameaças no relatório atual. Isso não garante que o arquivo seja seguro.'),
        findsOneWidget,
      );
    });

    testWidgets('3. Renderiza veredito suspicious', (WidgetTester tester) async {
      const stats = AnalysisStats(
        malicious: 0,
        suspicious: 3,
        undetected: 67,
      );

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.suspicious,
            stats: stats,
          ),
        ),
      );

      expect(find.text('Comportamento suspeito'), findsOneWidget);
      expect(find.text('3 / 70'), findsOneWidget);
      expect(
        find.text('mecanismos sinalizaram comportamento suspeito'),
        findsOneWidget,
      );
    });

    testWidgets('4. Renderiza veredito inconclusive e pending', (WidgetTester tester) async {
      const inconclusiveStats = AnalysisStats(
        malicious: 0,
        suspicious: 0,
        undetected: 0,
        harmless: 0,
        failure: 10,
      );

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.inconclusive,
            stats: inconclusiveStats,
          ),
        ),
      );

      expect(find.text('Resultado inconclusivo'), findsOneWidget);
      expect(find.text('0 / 10'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.pending,
            stats: AnalysisStats(),
          ),
        ),
      );

      expect(find.text('Análise em andamento'), findsOneWidget);
      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('5. Renderiza adequadamente no tema escuro AMOLED', (WidgetTester tester) async {
      const stats = AnalysisStats(
        malicious: 5,
        undetected: 65,
      );

      await tester.pumpWidget(
        _wrap(
          const ReportSummaryCard(
            verdict: ScanVerdict.malicious,
            stats: stats,
          ),
          isDark: true,
        ),
      );

      expect(find.text('Ameaça detectada'), findsOneWidget);
      expect(find.text('5 / 70'), findsOneWidget);
    });
  });
}
