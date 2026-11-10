import 'package:fileguard/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FileGuardApp inicializa com barra de navegação inferior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FileGuardApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Valida títulos e destinos da navegação inferior
    expect(find.text('FileGuard'), findsOneWidget);
    expect(find.text('Início'), findsWidgets); // no AppBar/Body e na NavBar
    expect(find.text('Analisador'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('Navegação entre abas via barra inferior funciona', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FileGuardApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Clica na aba Configurações
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Tema do Aplicativo'), findsOneWidget);
    expect(find.text('AMOLED'), findsOneWidget);

    // Clica na aba Analisador
    await tester.tap(find.text('Analisador'));
    await tester.pumpAndSettle();

    expect(find.text('Analisador'), findsWidgets);
  });

  testWidgets('Alternância de tema claro, escuro AMOLED e sistema', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FileGuardApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Navega para configurações
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    // Seleciona tema claro
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), equals(ThemeMode.light));

    // Seleciona tema AMOLED
    await tester.tap(find.text('AMOLED'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), equals(ThemeMode.dark));

    // Seleciona tema do Sistema
    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), equals(ThemeMode.system));
  });
}
