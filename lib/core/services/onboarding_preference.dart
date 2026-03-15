import 'package:shared_preferences/shared_preferences.dart';

/// Persistance de l'état d'onboarding (premier lancement).
abstract class OnboardingPreference {
  static const _kSeen = 'onboarding_seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeen) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeen, true);
  }
}
