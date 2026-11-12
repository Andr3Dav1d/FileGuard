import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/core/widgets/permission_dialog.dart';
import 'package:fileguard/core/widgets/progress_card.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/selected_file_info.dart';
import 'package:fileguard/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:fileguard/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:fileguard/features/scanner/presentation/screens/technical_details_screen.dart';
import 'package:fileguard/features/scanner/presentation/widgets/report_summary_card.dart';

class MockScannerNotifier extends ScannerNotifier {
  MockScannerNotifier(this.mockState);
  final ScannerState mockState;

  @override
  ScannerState build() => mockState;
}

Widget _wrapScannerScreen({
  required ScannerState state,
  bool isDark = false,
  GoRouter? router,
}) {
  final overrides = [
    scannerNotifierProvider.overrideWith(() => MockScannerNotifier(state)),
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
      home: const ScannerScreen(),
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
    'ESET-NOD32': const EngineResult(
      engineName: 'ESET-NOD32',
      category: 'malicious',
      result: 'PDF/Phishing',
    ),
    'Kaspersky': const EngineResult(
      engineName: 'Kaspersky',
      category: 'undetected',
    ),
    'ClamAV': const EngineResult(
      engineName: 'ClamAV',
      category: 'undetected',
    ),
  };

  final maliciousReport = ScanReport(
    id: 'test-malicious',
    sha256: '72a13d4f9e80b265c147a6e9d0f38b25c4e71a6d9b205f38a1c7e406d2b89f35',
    fileName: 'sample_bundle.zip',
    fileSize: 19503513, // ~18.6 MB
    scanDate: DateTime.utc(2026, 11, 10, 9, 41),
    fileExtension: '.zip',
    stats: const AnalysisStats(
      malicious: 2,
      suspicious: 0,
      undetected: 68,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.malicious,
    results: sampleEngines,
  );

  final cleanReport = ScanReport(
    id: 'test-clean',
    sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    fileName: 'document.pdf',
    fileSize: 251904, // 246 KB
    scanDate: DateTime.utc(2026, 11, 10, 9, 41),
    fileExtension: '.pdf',
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
    results: sampleEngines,
  );

  final suspiciousReport = ScanReport(
    id: 'test-suspicious',
    sha256: '55b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    fileName: 'installer.exe',
    fileSize: 1048576,
    scanDate: DateTime.utc(2026, 11, 10, 9, 41),
    fileExtension: '.exe',
    stats: const AnalysisStats(
      malicious: 0,
      suspicious: 2,
      undetected: 68,
      harmless: 0,
      timeout: 0,
      failure: 0,
      typeUnsupported: 0,
    ),
    verdict: ScanVerdict.suspicious,
    results: sampleEngines,
  );

  group('ScannerScreen Tests (Tela 51 Figma)', () {
    testWidgets('1. Renderiza estado Idle preservando seleção de arquivos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapScannerScreen(state: const ScannerState(step: ScannerStep.idle)),
      );

      expect(find.text('Analisador'), findsOneWidget);
      expect(find.text('Análise Rápida de Arquivos'), findsOneWidget);
      expect(find.text('Selecionar Arquivo'), findsOneWidget);
      expect(find.text('Como funciona o fluxo de segurança:'), findsOneWidget);
    });

    testWidgets('2. Renderiza resumo da análise com ReportSummaryCard e estados de detecção', (
      WidgetTester tester,
    ) async {
      // 2.1 Malicioso
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
        ),
      );

      expect(find.byType(ReportSummaryCard), findsOneWidget);
      expect(find.text('Ameaça detectada'), findsOneWidget);
      expect(find.text('2 / 70'), findsOneWidget);

      // 2.2 Sem detecções (aviso preventivo)
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: cleanReport,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ReportSummaryCard),
          matching: find.text('Nenhuma detecção'),
        ),
        findsOneWidget,
      );
      expect(find.text('0 / 70'), findsOneWidget);
      expect(
        find.text('Nenhum mecanismo detectou ameaças no relatório atual. Isso não garante que o arquivo seja seguro.'),
        findsOneWidget,
      );

      // 2.3 Suspeito
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: suspiciousReport,
          ),
        ),
      );

      expect(find.text('Comportamento suspeito'), findsOneWidget);
      expect(find.text('2 / 70'), findsOneWidget);
    });

    testWidgets('3. Exibe contexto do relatório, metadados e informações do arquivo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
        ),
      );

      // Contexto
      expect(find.text('sample_bundle.zip'), findsNWidgets(2)); // Contexto e Info
      expect(find.text('10/11/2026 · 09:41 UTC'), findsOneWidget);

      // Informações do arquivo
      expect(find.text('Informações do arquivo'), findsOneWidget);
      expect(find.text('Nome do arquivo'), findsOneWidget);
      expect(find.text('Tipo / tamanho'), findsOneWidget);
      expect(find.text('ZIP · 18.6 MB'), findsOneWidget);
      expect(find.text('Data da análise'), findsOneWidget);
      expect(find.text('Origem do relatório'), findsOneWidget);
      expect(find.text('VirusTotal API v3'), findsOneWidget);
    });

    testWidgets('4. Prévia dos 3 mecanismos prioriza ameaças e navega para relatório completo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
        ),
      );

      expect(find.text('Mecanismos de segurança'), findsOneWidget);
      expect(find.text('MECANISMO'), findsOneWidget);
      expect(find.text('RESULTADO'), findsOneWidget);

      // Motores da prévia
      expect(find.text('Bitdefender'), findsOneWidget);
      expect(find.text('Trojan.Generic'), findsOneWidget);
      expect(find.text('ESET-NOD32'), findsOneWidget);
      expect(find.text('PDF/Phishing'), findsOneWidget);
      expect(find.text('Kaspersky'), findsOneWidget);

      // Botão para ver todos os mecanismos
      expect(find.text('Ver os 4 mecanismos'), findsOneWidget);
    });

    testWidgets('5. SHA-256 copiável aciona clipboard e exibe feedback acessível', (
      WidgetTester tester,
    ) async {
      String? copiedHash;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copiedHash = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
        ),
      );

      final copyButton = find.text('Copiar impressão digital');
      await tester.tap(copyButton);
      await tester.pump();

      expect(copiedHash, equals(maliciousReport.sha256));
      expect(
        find.text('Hash SHA-256 copiado para a área de transferência.'),
        findsOneWidget,
      );
    });

    testWidgets('6. Navega para TechnicalDetailsScreen passando ScanReport no extra', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRoutes.scanner,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.scanner,
            builder: (context, state) => const ScannerScreen(),
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
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
          router: router,
        ),
      );

      final detailsButton = find.text('Detalhes técnicos');
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.byType(TechnicalDetailsScreen), findsOneWidget);
      expect(find.text('Detalhes técnicos'), findsOneWidget);
    });

    testWidgets('7. Ações de Compartilhar, Exportar e Aviso legal estão presentes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
        ),
      );

      expect(find.text('Compartilhar'), findsOneWidget);
      expect(find.text('Exportar'), findsOneWidget);
      expect(find.text('Abrir relatório no VirusTotal ↗'), findsOneWidget);
      expect(
        find.text('Os resultados refletem o relatório na data indicada, não uma proteção contínua do dispositivo.'),
        findsOneWidget,
      );
    });

    testWidgets('8. Compatibilidade com temas Claro e Escuro AMOLED', (
      WidgetTester tester,
    ) async {
      // Claro
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
          isDark: false,
        ),
      );

      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.lightBackground));

      // Escuro AMOLED
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.completed,
            report: maliciousReport,
          ),
          isDark: true,
        ),
      );

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.darkBackground));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
    });

    testWidgets('9. Preserva fluxos de análise: ProgressCard, PermissionDialog e Error', (
      WidgetTester tester,
    ) async {
      // 9.1 Uploading / Analyzing
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: const ScannerState(
            step: ScannerStep.uploading,
            statusText: 'Enviando arquivo...',
            uploadProgress: 0.5,
          ),
        ),
      );
      expect(find.byType(ProgressCard), findsOneWidget);

      // 9.2 Consent Dialog
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: const ScannerState(
            step: ScannerStep.promptConsent,
          ),
        ),
      );
      expect(find.byType(PermissionDialog), findsOneWidget);
      expect(find.text('Arquivo Não Catalogado'), findsOneWidget);

      // 9.3 Error Card
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: const ScannerState(
            step: ScannerStep.error,
            errorMessage: 'Cota de requisições excedida.',
          ),
        ),
      );
      expect(find.text('Atenção'), findsOneWidget);
      expect(find.text('Cota de requisições excedida.'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      // 9.4 Queued Card
      await tester.pumpWidget(
        _wrapScannerScreen(
          state: ScannerState(
            step: ScannerStep.queued,
            pendingAnalysisId: 'pending_123',
            selectedFile: SelectedFileInfo(
              name: 'async_file.bin',
              path: '/tmp/async_file.bin',
              size: 2048,
              sha256: 'abc123sha256',
              mimeType: 'application/octet-stream',
            ),
          ),
        ),
      );
      expect(find.text('Análise em processamento'), findsOneWidget);
      expect(find.text('Verificar status agora'), findsOneWidget);
      expect(find.text('Voltar ao início'), findsOneWidget);
    });
  });
}
