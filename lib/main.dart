import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';

class InitialHasSeenNotifier extends HasSeenOnboardingNotifier {
  InitialHasSeenNotifier(this._initialValue);
  final bool _initialValue;

  @override
  bool build() => _initialValue;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool(kHasSeenOnboardingKey) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        hasSeenOnboardingProvider.overrideWith(
          () => InitialHasSeenNotifier(hasSeen),
        ),
      ],
      child: const FileGuardApp(),
    ),
  );
}
