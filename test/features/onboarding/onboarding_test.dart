import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fileguard/core/theme/app_theme.dart';
import 'package:fileguard/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'fg_has_seen_onboarding': false});
  });

  group('Onboarding / Landing Page Tests', () {
    testWidgets('Renderiza passo 1 (Boas-vindas) e avança pelas 3 etapas', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Passo 1: Boas-vindas
      expect(find.text('Verifique seus arquivos'), findsOneWidget);
      expect(find.text('Análise com o VirusTotal'), findsOneWidget);
      expect(find.text('01 / 03   •   CONHEÇA SEUS ARQUIVOS'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);

      // Avança para o Passo 2
      await tester.ensureVisible(find.text('Começar'));
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      // Passo 2: Como funciona
      expect(find.text('Consulta por SHA-256'), findsOneWidget);
      expect(find.text('Relatório Existente'), findsOneWidget);
      expect(find.text('02 / 03   •   COMO FUNCIONA A ANÁLISE'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);

      // Avança para o Passo 3
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Passo 3: Privacidade
      expect(find.text('Sobre a Análise'), findsOneWidget);
      expect(find.text('Consultar hash ≠ enviar arquivo'), findsOneWidget);
      expect(find.text('03 / 03   •   PRIVACIDADE EM PRIMEIRO LUGAR'), findsOneWidget);
      expect(find.text('Configurar minha API Key'), findsOneWidget);
    });

    testWidgets('Botão voltar navega para etapa anterior', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Avança para passo 2
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();
      expect(find.text('Como funciona'), findsOneWidget);

      // Clica em voltar
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // Retorna para passo 1
      expect(find.text('Boas-vindas'), findsOneWidget);
      expect(find.text('Verifique seus arquivos'), findsOneWidget);
    });
  });
}
