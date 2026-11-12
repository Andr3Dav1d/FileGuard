import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/core/widgets/file_list_tile.dart';
import 'package:fileguard/features/history/presentation/providers/history_provider.dart';
import 'package:fileguard/features/history/presentation/screens/history_screen.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';
import 'package:fileguard/features/scanner/presentation/screens/technical_details_screen.dart';

class MockHistoryNotifier extends HistoryNotifier {
  MockHistoryNotifier(this.initialReports);
  final List<ScanReport> initialReports;

  @override
  Future<List<ScanReport>> build() async => initialReports;

  @override
  Future<void> deleteReport(String id) async {
    initialReports.removeWhere((r) => r.id == id);
    state = AsyncData([...initialReports]);
  }
}

Widget _wrapHistoryScreen({
  required List<ScanReport> reports,
  bool isDark = false,
  GoRouter? router,
}) {
  final overrides = [
    historyNotifierProvider.overrideWith(() => MockHistoryNotifier([...reports])),
  ];

  if (router != null) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp.router(
        key: ValueKey<bool>(isDark),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    key: UniqueKey(),
    overrides: overrides,
    child: MaterialApp(
      key: ValueKey<bool>(isDark),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HistoryScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  final sampleEngines = <String, EngineResult>{
    'Bitdefender': const EngineResult(
      engineName: 'Bitdefender',
      category: 'malicious',
      result: 'Trojan.Generic',
    ),
    'Kaspersky': const EngineResult(
      engineName: 'Kaspersky',
      category: 'undetected',
    ),
  };

  final fullV2Report = ScanReport(
    id: 'report-v2-full',
    sha256: '72a13d4f9e80b265c147a6e9d0f38b25c4e71a6d9b205f38a1c7e406d2b89f35',
    md5: '44d88612fea8a8f36de82e1278abb02f',
    sha1: '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12',
    fileName: 'invoice_recovered.pdf',
    fileSize: 251904, // 246 KB
    scanDate: DateTime.utc(2026, 11, 10, 9, 41),
    fileExtension: '.pdf',
    mimeType: 'application/pdf',
    reputation: 15,
    tags: const <String>['pdf', 'signed'],
    totalVotes: const TotalVotes(harmless: 8, malicious: 0),
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

  final legacyV1Report = ScanReport(
    id: 'report-v1-legacy',
    sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    fileName: 'old_sample.bin',
    fileSize: 1024,
    scanDate: DateTime.utc(2025, 1, 1, 12, 0),
    stats: const AnalysisStats(
      malicious: 0,
      suspicious: 0,
      undetected: 70,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.noDetections,
    results: const <String, EngineResult>{},
  );

  final incompleteReport = ScanReport(
    id: 'report-incomplete',
    sha256: '',
    fileName: 'corrupt_entry',
    fileSize: 0,
    scanDate: DateTime.fromMillisecondsSinceEpoch(0),
    stats: const AnalysisStats(
      malicious: 0,
      suspicious: 0,
      undetected: 0,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.inconclusive,
  );

  group('HistoryScreen Tests (Etapa 5C)', () {
    testWidgets('1. Exibe estado vazio quando não há registros no histórico', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico'), findsOneWidget);
      expect(find.text('Nenhuma análise registrada'), findsOneWidget);
      expect(
        find.text('Quando você verificar arquivos ou pacotes APK no Analisador, os relatórios ficarão salvos aqui offline.'),
        findsOneWidget,
      );
    });

    testWidgets('2. Lista registros do histórico com formatação correta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: [fullV2Report, legacyV1Report]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FileListTile), findsNWidgets(2));
      expect(find.text('invoice_recovered.pdf'), findsOneWidget);
      expect(find.text('old_sample.bin'), findsOneWidget);
      expect(find.text('Ameaça · 1/2'), findsOneWidget);
      expect(find.text('Sem detecções · 0/70'), findsOneWidget);
    });

    testWidgets('3. Abertura e navegação para detalhes com ScanReport completo persistido', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRoutes.history,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.technicalDetails,
            builder: (context, state) {
              final report = state.extra as ScanReport?;
              return TechnicalDetailsScreen(report: report!);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapHistoryScreen(
          reports: [fullV2Report],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      // Toca no item do histórico
      final tile = find.text('invoice_recovered.pdf');
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      // Confirma que navegou para TechnicalDetailsScreen
      expect(find.byType(TechnicalDetailsScreen), findsOneWidget);
      expect(find.text('Detalhes técnicos'), findsOneWidget);

      // Metadados recuperados
      expect(find.text('invoice_recovered.pdf'), findsOneWidget);
      expect(find.text('246 KB'), findsOneWidget);
      expect(find.text('application/pdf'), findsOneWidget);
      expect(find.text('.pdf'), findsOneWidget);

      // Hashes recuperados
      expect(find.text(fullV2Report.sha256), findsOneWidget);
      expect(find.text(fullV2Report.md5!), findsOneWidget);
      expect(find.text(fullV2Report.sha1!), findsOneWidget);

      // Reputação e tags recuperadas
      expect(find.text('Comunidade VirusTotal'), findsOneWidget);
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('signed'), findsOneWidget);

      // Resultados individuais de mecanismos preservados
      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('Trojan.Generic'), findsOneWidget);
      expect(find.text('Kaspersky'), findsOneWidget);
    });

    testWidgets('4. Compatibilidade com relatórios antigos / backups v1 sem resultados individuais', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRoutes.history,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.technicalDetails,
            builder: (context, state) {
              final report = state.extra as ScanReport?;
              return TechnicalDetailsScreen(report: report!);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapHistoryScreen(
          reports: [legacyV1Report],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.text('old_sample.bin');
      await tester.tap(tile);
      await tester.pumpAndSettle();

      // Navegou sem erros
      expect(find.byType(TechnicalDetailsScreen), findsOneWidget);
      expect(find.text('old_sample.bin'), findsOneWidget);

      // Hashes e campos ausentes omitidos
      expect(find.text('Impressão digital MD5'), findsNothing);
      expect(find.text('Impressão digital SHA-1'), findsNothing);
      expect(find.text('Comunidade VirusTotal'), findsNothing);

      // Tabela de mecanismos exibe estado vazio apropriado
      expect(find.text('Nenhum mecanismo encontrado'), findsOneWidget);
      expect(find.text('0 detecções + 70 sem detecção = 70 mecanismos.'), findsOneWidget);
    });

    testWidgets('5. Tratamento de registros incompletos ou corrompidos sem derrubar a tela', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: [incompleteReport]),
      );
      await tester.pumpAndSettle();

      expect(find.text('corrupt_entry'), findsOneWidget);
      expect(find.text('Tamanho desconhecido · Data desconhecida'), findsOneWidget);
      expect(find.byType(FileListTile), findsOneWidget);
    });

    testWidgets('6. Exclusão individual de item via Dismissible com confirmação', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: [fullV2Report]),
      );
      await tester.pumpAndSettle();

      expect(find.text('invoice_recovered.pdf'), findsOneWidget);

      // Arrasta da direita para a esquerda para disparar o Dismissible
      await tester.drag(find.text('invoice_recovered.pdf'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Diálogo de confirmação de exclusão
      expect(find.text('Excluir registro?'), findsOneWidget);
      expect(find.text('Deseja remover "invoice_recovered.pdf" do histórico?'), findsOneWidget);

      // Confirma exclusão
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      // Item removido
      expect(find.text('invoice_recovered.pdf'), findsNothing);
      expect(find.text('"invoice_recovered.pdf" removido do histórico.'), findsOneWidget);
    });

    testWidgets('7. Compatibilidade com temas Claro e Escuro AMOLED', (
      WidgetTester tester,
    ) async {
      // Tema Claro
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: [fullV2Report], isDark: false),
      );
      await tester.pumpAndSettle();
      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.lightBackground));

      // Tema Escuro AMOLED
      await tester.pumpWidget(
        _wrapHistoryScreen(reports: [fullV2Report], isDark: true),
      );
      await tester.pumpAndSettle();
      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.darkBackground));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
    });
  });
}
