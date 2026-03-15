import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des préférences bénéficiaire (par utilisateur).
abstract class BeneficiaryPreference {
  static String _keyStarted(String userId) => 'beneficiary_started_$userId';

  static Future<bool> hasStartedEvaluation(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStarted(userId)) ?? false;
  }

  static Future<void> markEvaluationStarted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStarted(userId), true);
  }
}
