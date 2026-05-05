import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call LocalStorage.init() first.');
    }
    return _prefs!;
  }

  // Gateway
  static String? getGatewayUrl() => prefs.getString(AppConfig.keyGatewayUrl);
  static Future<void> setGatewayUrl(String url) => prefs.setString(AppConfig.keyGatewayUrl, url);

  static String? getGatewayToken() => prefs.getString(AppConfig.keyGatewayToken);
  static Future<void> setGatewayToken(String token) => prefs.setString(AppConfig.keyGatewayToken, token);

  // Theme
  static bool getDarkMode() => prefs.getBool(AppConfig.keyThemeMode) ?? true;
  static Future<void> setDarkMode(bool value) => prefs.setBool(AppConfig.keyThemeMode, value);

  // Biometrics
  static bool getUseBiometrics() => prefs.getBool(AppConfig.keyUseBiometrics) ?? false;
  static Future<void> setUseBiometrics(bool value) => prefs.setBool(AppConfig.keyUseBiometrics, value);

  // Onboarding
  static bool isOnboardingComplete() => prefs.getBool(AppConfig.keyOnboardingComplete) ?? false;
  static Future<void> setOnboardingComplete(bool value) => prefs.setBool(AppConfig.keyOnboardingComplete, value);

  // Clear all
  static Future<void> clearAll() async {
    await prefs.clear();
  }

  // Session data
  static Future<void> saveSessionData(String key, String value) async {
    await prefs.setString('session_$key', value);
  }

  static String? getSessionData(String key) {
    return prefs.getString('session_$key');
  }
}
