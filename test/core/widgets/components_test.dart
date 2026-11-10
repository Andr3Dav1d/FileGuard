import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  group('1. FileGuardButton Tests', () {
    testWidgets('Filled, Tonal e Danger renderizam corretamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: <Widget>[
              FileGuardButton(
                label: 'Filled Button',
                style: FileGuardButtonStyle.filled,
                onPressed: () {},
              ),
              FileGuardButton(
                label: 'Tonal Button',
                style: FileGuardButtonStyle.tonal,
                onPressed: () {},
              ),
              FileGuardButton(
                label: 'Danger Button',
                style: FileGuardButtonStyle.danger,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Filled Button'), findsOneWidget);
      expect(find.text('Tonal Button'), findsOneWidget);
      expect(find.text('Danger Button'), findsOneWidget);
    });

    testWidgets('Disabled e Loading bloqueiam toques e exibem status', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          FileGuardButton(
            label: 'Clique aqui',
            isLoading: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('Carregando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FileGuardButton));
      expect(tapped, isFalse);
    });
  });

  group('2. DetectionBadge Tests', () {
    testWidgets('Renderiza os 5 estados semânticos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: <Widget>[
              DetectionBadge(status: DetectionBadgeStatus.malicious),
              DetectionBadge(status: DetectionBadgeStatus.suspicious),
              DetectionBadge(status: DetectionBadgeStatus.noDetections),
              DetectionBadge(status: DetectionBadgeStatus.inconclusive),
              DetectionBadge(status: DetectionBadgeStatus.pending),
            ],
          ),
        ),
      );

      expect(find.text('12 / 70 · Malicioso'), findsOneWidget);
      expect(find.text('2 / 70 · Suspeito'), findsOneWidget);
      expect(find.text('0 / 70 · Nenhuma detecção'), findsOneWidget);
      expect(find.text('18 / 70 · Inconclusivo'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
    });
  });

  group('3. StatisticCard Tests', () {
    testWidgets('Exibe valor e rótulo e responde a toques', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          StatisticCard(
            value: '128',
            label: 'Analisados',
            type: StatisticCardType.total,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('128'), findsOneWidget);
      expect(find.text('Analisados'), findsOneWidget);

      await tester.tap(find.byType(StatisticCard));
      expect(tapped, isTrue);
    });
  });

  group('4. FileListTile Tests', () {
    testWidgets('Exibe nome, metadados e chevron', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          FileListTile(
            name: 'documento.pdf',
            detail: 'PDF · 2,4 MB · Hoje',
            status: 'Nenhuma detecção · 0 / 70',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('documento.pdf'), findsOneWidget);
      expect(find.text('PDF · 2,4 MB · Hoje'), findsOneWidget);
      expect(find.text('Nenhuma detecção · 0 / 70'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(FileListTile));
      expect(tapped, isTrue);
    });
  });

  group('5. ProgressCard Tests', () {
    testWidgets('Exibe estados de progresso e falha', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: <Widget>[
              ProgressCard(state: ProgressCardState.uploading),
              ProgressCard(state: ProgressCardState.failed),
            ],
          ),
        ),
      );

      expect(find.text('Enviando · 64%'), findsOneWidget);
      expect(find.text('Sem conexão com a rede'), findsOneWidget);
    });
  });

  group('6. ApiKeyField Tests', () {
    testWidgets('Alterna visibilidade da chave', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController(text: 'secret_api_key_123');

      await tester.pumpWidget(
        _wrap(
          ApiKeyField(
            controller: controller,
            state: ApiKeyFieldState.hidden,
          ),
        ),
      );

      expect(find.text('API Key do VirusTotal'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Toca para alternar visibilidade
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('7. PermissionDialog Tests', () {
    testWidgets('Renderiza opções de envio e cancelamento', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PermissionDialog(
            type: PermissionDialogType.upload,
          ),
        ),
      );

      expect(find.text('Enviar este arquivo?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Enviar arquivo'), findsOneWidget);
    });
  });

  group('8. PreferenceSwitch Tests', () {
    testWidgets('Alterna valor ao ser acionado', (
      WidgetTester tester,
    ) async {
      var state = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              PreferenceSwitch(
                title: 'Notificações',
                value: state,
                onChanged: (val) {
                  setState(() {
                    state = val;
                  });
                },
              ),
            );
          },
        ),
      );

      expect(find.text('Notificações'), findsOneWidget);

      await tester.tap(find.byType(PreferenceSwitch));
      await tester.pumpAndSettle();

      expect(state, isTrue);
    });
  });

  group('9. ScanFAB Tests', () {
    testWidgets('Aciona callback de clique', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          ScanFAB(
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_center_focus), findsOneWidget);

      await tester.tap(find.byType(ScanFAB));
      expect(tapped, isTrue);
    });
  });

  group('10. FileGuardAppBar Tests', () {
    testWidgets('Exibe título e ações', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          FileGuardAppBar(
            title: 'Resultado da análise',
            showBackButton: true,
            actions: const <Widget>[
              Icon(Icons.more_horiz),
            ],
          ),
        ),
      );

      expect(find.text('Resultado da análise'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });
  });
}
