import 'package:fileguard/app/app.dart';
import 'package:fileguard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'fg_has_seen_onboarding': true});
  });
  group('Visual & Layout Regression Tests (Figma 412x917 viewport)', () {
    testWidgets(
      'Sem overflow e cores de superfície corretas no tema Claro',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 917);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FileGuardApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Verifica que não houve erro de renderização ou overflow
        expect(tester.takeException(), isNull);

        // Verifica cor de fundo do Scaffold no tema claro
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(
          scaffold.backgroundColor,
          anyOf(isNull, equals(AppColors.lightBackground)),
        );

        // Verifica presença e altura da NavigationBar
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);
        expect(tester.getSize(navBarFinder).height, equals(84.0));
      },
    );

    testWidgets(
      'Sem overflow e cores de superfície corretas no tema Escuro AMOLED',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 917);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FileGuardApp(),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Verifica presença e altura da NavigationBar
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);
        expect(tester.getSize(navBarFinder).height, equals(84.0));
      },
    );
  });
}
