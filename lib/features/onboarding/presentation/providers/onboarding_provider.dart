import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kHasSeenOnboardingKey = 'fg_has_seen_onboarding';

/// Provedor síncrono para o status de conclusão do onboarding.
final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
  HasSeenOnboardingNotifier.new,
);

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setHasSeen(bool value) {
    state = value;
  }

  Future<void> completeOnboarding() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHasSeenOnboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kHasSeenOnboardingKey);
  }
}
