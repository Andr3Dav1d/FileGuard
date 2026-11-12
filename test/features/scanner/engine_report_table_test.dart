import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/presentation/widgets/engine_report_table.dart';

Widget _wrap(Widget child, {bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('EngineReportTable Tests', () {
    final Map<String, EngineResult> sampleEngines = {
      'Bitdefender': const EngineResult(
        engineName: 'Bitdefender',
        category: 'malicious',
        result: 'Trojan.Generic',
        method: 'blacklist',
      ),
      'Kaspersky': const EngineResult(
        engineName: 'Kaspersky',
        category: 'suspicious',
        result: 'HEUR:Trojan.PDF',
        method: 'heuristic',
      ),
      'ClamAV': const EngineResult(
        engineName: 'ClamAV',
        category: 'undetected',
        result: null,
      ),
      'Google': const EngineResult(
        engineName: 'Google',
        category: 'harmless',
        result: 'clean',
      ),
      'SlowAntivirus': const EngineResult(
        engineName: 'SlowAntivirus',
        category: 'confirmed-timeout',
      ),
      'BrokenEngine': const EngineResult(
        engineName: 'BrokenEngine',
        category: 'failure',
      ),
      'UnsupportedEngine': const EngineResult(
        engineName: 'UnsupportedEngine',
        category: 'type-unsupported',
      ),
      'AlienEngine': const EngineResult(
        engineName: 'AlienEngine',
        category: 'unknown_category_xyz',
        result: 'custom_alert',
      ),
    };

    testWidgets('1. Renderiza cabeçalho, colunas e lista de mecanismos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
        ),
      );

      expect(find.text('Mecanismos de segurança'), findsOneWidget);
      expect(find.text('MECANISMO'), findsOneWidget);
      expect(find.text('RESULTADO'), findsOneWidget);

      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('Trojan.Generic'), findsOneWidget);

      expect(find.text('HEUR:Trojan.PDF'), findsOneWidget);

      expect(find.text('ClamAV'), findsOneWidget);
      expect(find.text('Nenhuma detecção'), findsOneWidget);
    });

    testWidgets('2. Filtra por busca textual (nome do motor e diagnóstico)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
        ),
      );

      // Digita "Kaspersky" no campo de busca
      await tester.enterText(find.byType(TextField), 'Kaspersky');
      await tester.pumpAndSettle();

      // Confirma que apenas o resultado de Kaspersky está visível na tabela
      expect(find.text('HEUR:Trojan.PDF'), findsOneWidget);
      expect(find.text('Bitdefender'), findsNothing);
      expect(find.text('ClamAV'), findsNothing);

      // Limpa busca
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('HEUR:Trojan.PDF'), findsOneWidget);
    });

    testWidgets('3. Filtra por chips de categoria (Maliciosos, Suspeitos, Timeout, etc.)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
        ),
      );

      // Toca no chip "Maliciosos (1)"
      await tester.tap(find.text('Maliciosos (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('HEUR:Trojan.PDF'), findsNothing);
      expect(find.text('ClamAV'), findsNothing);

      // Toca no chip "Suspeitos (1)"
      await tester.tap(find.text('Suspeitos (1)'));
      await tester.pumpAndSettle();

      expect(find.text('HEUR:Trojan.PDF'), findsOneWidget);
      expect(find.text('Bitdefender'), findsNothing);

      // Rola a barra horizontal de chips para garantir visibilidade do chip "Timeout (1)"
      await tester.ensureVisible(find.text('Timeout (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Timeout (1)'));
      await tester.pumpAndSettle();

      expect(find.text('SlowAntivirus'), findsOneWidget);
      expect(find.text('Tempo limite'), findsOneWidget);
    });

    testWidgets('4. Preserva categoria Unknown sem classificar incorretamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
        ),
      );

      // Rola a lista vertical para encontrar o motor com categoria desconhecida
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('AlienEngine'), findsOneWidget);
      expect(find.text('custom_alert'), findsOneWidget);
    });

    testWidgets('5. Exibe estado vazio quando busca não tem correspondência', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
        ),
      );

      await tester.enterText(find.byType(TextField), 'InexistenteXYZ123');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum mecanismo encontrado'), findsOneWidget);
      expect(
        find.text('Nenhum resultado corresponde à pesquisa ou filtro selecionado.'),
        findsOneWidget,
      );
    });

    testWidgets('6. Renderiza no tema escuro AMOLED', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EngineReportTable(results: sampleEngines),
          isDark: true,
        ),
      );

      expect(find.text('Mecanismos de segurança'), findsOneWidget);
      expect(find.text('Bitdefender'), findsOneWidget);
    });
  });
}
