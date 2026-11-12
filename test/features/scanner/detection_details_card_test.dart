import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/presentation/widgets/detection_details_card.dart';
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
  group('DetectionDetailsCard Tests', () {
    final Map<String, EngineResult> sampleEngines = {
      'Bitdefender': const EngineResult(
        engineName: 'Bitdefender',
        category: 'malicious',
        result: 'Trojan.Generic',
      ),
      'Kaspersky': const EngineResult(
        engineName: 'Kaspersky',
        category: 'malicious',
        result: 'HEUR:Trojan.Generic',
      ),
      'ClamAV': const EngineResult(
        engineName: 'ClamAV',
        category: 'undetected',
      ),
    };

    testWidgets('1. Inicializa colapsado e exibe título, subtítulo e chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DetectionDetailsCard(
            results: sampleEngines,
            initialExpanded: false,
          ),
        ),
      );

      expect(find.text('Detalhes da detecção'), findsOneWidget);
      expect(
        find.text('2 mecanismos sinalizaram este arquivo. Toque para ver a lista completa.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // No estado colapsado, o EngineReportTable tem tamanho 0 (sizeFactor = 0)
      final sizeTransition = tester.widget<SizeTransition>(find.byType(SizeTransition));
      expect(sizeTransition.sizeFactor.value, equals(0.0));
    });

    testWidgets('2. Expande ao tocar no cabeçalho e notifica callback', (
      WidgetTester tester,
    ) async {
      bool? expandedState;

      await tester.pumpWidget(
        _wrap(
          DetectionDetailsCard(
            results: sampleEngines,
            initialExpanded: false,
            onExpansionChanged: (val) => expandedState = val,
          ),
        ),
      );

      // Toca para expandir
      await tester.tap(find.text('Detalhes da detecção'));
      await tester.pumpAndSettle();

      expect(expandedState, isTrue);
      expect(
        find.text('2 mecanismos sinalizaram ameaças ou suspeitas neste arquivo.'),
        findsOneWidget,
      );

      // Confirma que a tabela e os motores estão visíveis
      expect(find.byType(EngineReportTable), findsOneWidget);
      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('Kaspersky'), findsOneWidget);

      // Toca novamente para recolher
      await tester.tap(find.text('Detalhes da detecção'));
      await tester.pumpAndSettle();

      expect(expandedState, isFalse);
      expect(
        find.text('2 mecanismos sinalizaram este arquivo. Toque para ver a lista completa.'),
        findsOneWidget,
      );
    });

    testWidgets('3. Exibe subtítulo amigável quando nenhum motor detecta ameaças', (
      WidgetTester tester,
    ) async {
      final cleanEngines = {
        'Engine1': const EngineResult(engineName: 'Engine1', category: 'undetected'),
        'Engine2': const EngineResult(engineName: 'Engine2', category: 'harmless'),
      };

      await tester.pumpWidget(
        _wrap(
          DetectionDetailsCard(
            results: cleanEngines,
            initialExpanded: false,
          ),
        ),
      );

      expect(
        find.text('Nenhum mecanismo detectou ameaças. Toque para ver todos os 2 mecanismos.'),
        findsOneWidget,
      );
    });

    testWidgets('4. Renderiza corretamente no tema escuro AMOLED', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DetectionDetailsCard(
            results: sampleEngines,
            initialExpanded: true,
          ),
          isDark: true,
        ),
      );

      expect(find.text('Detalhes da detecção'), findsOneWidget);
      expect(find.byType(EngineReportTable), findsOneWidget);
    });
  });
}
