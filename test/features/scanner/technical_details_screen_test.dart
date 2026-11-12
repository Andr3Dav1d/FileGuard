import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/core/widgets/file_guard_app_bar.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';
import 'package:fileguard/features/scanner/presentation/screens/technical_details_screen.dart';
import 'package:fileguard/features/scanner/presentation/widgets/engine_report_table.dart';

Widget _wrap(Widget child, {bool isDark = false}) {
  return MaterialApp(
    key: ValueKey<bool>(isDark),
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleEngines = <String, EngineResult>{
    'Bitdefender': const EngineResult(
      engineName: 'Bitdefender',
      category: 'malicious',
      result: 'Trojan.Generic',
    ),
    'ClamAV': const EngineResult(
      engineName: 'ClamAV',
      category: 'undetected',
    ),
  };

  final fullReport = ScanReport(
    id: 'test-sha256',
    sha256: '8c4f9e2a6b1d0f7352a8c9e4d6b7f1039a2e5c8d4f6b0a173e9c2d5f8b1a6047',
    md5: '44d88612fea8a8f36de82e1278abb02f',
    sha1: '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12',
    fileName: 'invoice_nov.pdf',
    fileSize: 251904, // 246 KB
    scanDate: DateTime.utc(2026, 11, 10, 9, 41),
    mimeType: 'application/pdf',
    fileExtension: '.pdf',
    reputation: 10,
    tags: const <String>['pdf', 'signed', 'trojan'],
    totalVotes: const TotalVotes(harmless: 5, malicious: 1),
    stats: const AnalysisStats(
      malicious: 1,
      suspicious: 0,
      undetected: 1,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.malicious,
    results: sampleEngines,
  );

  final minimalReport = ScanReport(
    id: 'min-sha256',
    sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    fileName: 'empty.txt',
    fileSize: 0,
    scanDate: DateTime.utc(2026, 11, 10, 10, 0),
    stats: const AnalysisStats(
      malicious: 0,
      suspicious: 0,
      undetected: 0,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.noDetections,
    results: const <String, EngineResult>{},
  );

  group('TechnicalDetailsScreen Tests', () {
    testWidgets('1. Renderiza metadados completos do arquivo com formatação correta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      expect(find.text('Detalhes técnicos'), findsOneWidget);
      expect(find.text('Metadados do arquivo'), findsOneWidget);
      expect(find.text('invoice_nov.pdf'), findsOneWidget);
      expect(find.text('246 KB'), findsOneWidget);
      expect(find.text('application/pdf'), findsOneWidget);
      expect(find.text('.pdf'), findsOneWidget);
      expect(find.text('10/11/2026, 09:41 UTC'), findsOneWidget);
    });

    testWidgets('2. Exibe os três hashes criptográficos (SHA-256, MD5, SHA-1)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      expect(find.text('Impressão digital SHA-256'), findsOneWidget);
      expect(find.text(fullReport.sha256), findsOneWidget);
      expect(find.text('Copiar SHA-256'), findsOneWidget);

      expect(find.text('Impressão digital MD5'), findsOneWidget);
      expect(find.text(fullReport.md5!), findsOneWidget);
      expect(find.text('Copiar MD5'), findsOneWidget);

      expect(find.text('Impressão digital SHA-1'), findsOneWidget);
      expect(find.text(fullReport.sha1!), findsOneWidget);
      expect(find.text('Copiar SHA-1'), findsOneWidget);
    });

    testWidgets('3. Trata campos opcionais ausentes sem inventar informações', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: minimalReport)));

      // Hashes opcionais ausentes não devem ser exibidos
      expect(find.text('Impressão digital MD5'), findsNothing);
      expect(find.text('Impressão digital SHA-1'), findsNothing);

      // Comunidade ausente não deve ser exibida
      expect(find.text('Comunidade VirusTotal'), findsNothing);

      // MIME e Extensão ausentes não devem ser exibidos
      expect(find.text('MIME'), findsNothing);
      expect(find.text('Extensão'), findsNothing);

      // SHA-256 e Metadados básicos permanecem visíveis
      expect(find.text('Impressão digital SHA-256'), findsOneWidget);
      expect(find.text('empty.txt'), findsOneWidget);
      expect(find.text('Tamanho desconhecido'), findsOneWidget);
    });

    testWidgets('4. Cópia dos hashes copia para o clipboard e exibe feedback acessível', (
      WidgetTester tester,
    ) async {
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardText = (methodCall.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      // Copiar SHA-256
      final copyShaButton = find.text('Copiar SHA-256');
      await tester.ensureVisible(copyShaButton);
      await tester.tap(copyShaButton);
      await tester.pump();

      expect(clipboardText, equals(fullReport.sha256));
      expect(find.text('SHA-256 copiado para a área de transferência.'), findsOneWidget);

      // Copiar MD5
      final copyMd5Button = find.text('Copiar MD5');
      await tester.ensureVisible(copyMd5Button);
      await tester.tap(copyMd5Button);
      await tester.pump();

      expect(clipboardText, equals(fullReport.md5));
      expect(find.text('MD5 copiado para a área de transferência.'), findsOneWidget);
    });

    testWidgets('5. Renderiza a tabela de mecanismos EngineReportTable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      expect(find.byType(EngineReportTable), findsOneWidget);
      expect(find.text('Todos os resultados dos mecanismos'), findsOneWidget);
      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('Trojan.Generic'), findsOneWidget);
      expect(find.text('ClamAV'), findsOneWidget);
    });

    testWidgets('6. Resumo inferior exibe contadores de detecções, sem detecção e total', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      final summaryNotice = find.text('1 detecção + 1 sem detecção = 2 mecanismos.');
      await tester.ensureVisible(summaryNotice);
      expect(summaryNotice, findsOneWidget);
    });

    testWidgets('7. Exibe dados de comunidade e tags quando disponíveis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport)));

      expect(find.text('Comunidade VirusTotal'), findsOneWidget);
      expect(find.text('Reputação: '), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(
        find.text('Votos da comunidade: 5 inofensivo(s) · 1 malicioso(s)'),
        findsOneWidget,
      );
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('signed'), findsOneWidget);
      expect(find.text('trojan'), findsOneWidget);
    });

    testWidgets('8. Compatibilidade com temas Claro e Escuro AMOLED', (
      WidgetTester tester,
    ) async {
      // Tema Claro
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport), isDark: false));
      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.lightBackground));

      // Tema Escuro AMOLED
      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: fullReport), isDark: true));
      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.darkBackground));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
    });

    testWidgets('9. Navegação via GoRouter para TechnicalDetailsScreen com extra', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push(
                    AppRoutes.technicalDetails,
                    extra: fullReport,
                  ),
                  child: const Text('Abrir Detalhes'),
                ),
              ),
            ),
          ),
          GoRoute(
            name: 'technicalDetails',
            path: AppRoutes.technicalDetails,
            builder: (context, state) {
              final report = state.extra as ScanReport?;
              return TechnicalDetailsScreen(report: report!);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      );

      expect(find.text('Abrir Detalhes'), findsOneWidget);

      await tester.tap(find.text('Abrir Detalhes'));
      await tester.pumpAndSettle();

      // Verifica que navegou com sucesso e os detalhes estão na tela
      expect(find.byType(TechnicalDetailsScreen), findsOneWidget);
      expect(find.text('invoice_nov.pdf'), findsOneWidget);

      // Testa botão voltar da FileGuardAppBar
      final backButton = find.byTooltip('Back').evaluate().isNotEmpty
          ? find.byTooltip('Back')
          : find.byType(FileGuardAppBar);
      expect(backButton, findsOneWidget);
    });

    testWidgets('10. Resumo inferior inclui contagem de motores não analisados (timeout/falha)', (
      WidgetTester tester,
    ) async {
      final reportWithOther = ScanReport(
        id: 'report-other-engines',
        sha256: 'a1b2c3d4e5f6',
        fileName: 'sample_timeout.exe',
        fileSize: 1048576,
        scanDate: DateTime.utc(2026, 11, 10, 12, 0),
        stats: const AnalysisStats(
          malicious: 2,
          suspicious: 0,
          undetected: 65,
          harmless: 0,
          timeout: 2,
          failure: 1,
          typeUnsupported: 0,
        ),
        verdict: ScanVerdict.malicious,
        results: const <String, EngineResult>{
          'EngineA': EngineResult(engineName: 'EngineA', category: 'malicious', result: 'Trojan'),
          'EngineB': EngineResult(engineName: 'EngineB', category: 'malicious', result: 'Virus'),
          'EngineC': EngineResult(engineName: 'EngineC', category: 'undetected'),
          'EngineD': EngineResult(engineName: 'EngineD', category: 'timeout'),
          'EngineE': EngineResult(engineName: 'EngineE', category: 'failure'),
        },
      );

      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: reportWithOther)));

      // 2 detecções + 1 sem detecção + 2 não analisados = 5 mecanismos.
      final summaryNotice = find.text('2 detecções + 1 sem detecção + 2 não analisados = 5 mecanismos.');
      await tester.ensureVisible(summaryNotice);
      expect(summaryNotice, findsOneWidget);
    });

    testWidgets('11. Trata scanDate com millisecondsSinceEpoch <= 0 como "Data não disponível"', (
      WidgetTester tester,
    ) async {
      final reportZeroDate = ScanReport(
        id: 'report-zero-date',
        sha256: 'zero_date_hash',
        fileName: 'legacy_file.bin',
        fileSize: 2048,
        scanDate: DateTime.fromMillisecondsSinceEpoch(0),
        stats: const AnalysisStats(
          malicious: 0,
          suspicious: 0,
          undetected: 10,
          harmless: 0,
          timeout: 0,
          failure: 0,
          typeUnsupported: 0,
        ),
        verdict: ScanVerdict.noDetections,
        results: const <String, EngineResult>{},
      );

      await tester.pumpWidget(_wrap(TechnicalDetailsScreen(report: reportZeroDate)));

      expect(find.text('Data não disponível'), findsOneWidget);
    });
  });
}
