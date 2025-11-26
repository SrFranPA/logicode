import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyOnboarding = 'onboarding_completed';

  /// Guarda si el onboarding ya se completó
  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, value);
  }

  /// Obtiene si el onboarding ya se completó
  Future<bool> getOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarding) ?? false;
  }
}
