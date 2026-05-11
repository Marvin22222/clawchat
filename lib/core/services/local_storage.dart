import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';

/// Voice input mode enum
enum VoiceInputMode {
  pushToTalk,
  voiceActivation,
}

extension VoiceInputModeExtension on VoiceInputMode {
  String get value {
    switch (this) {
      case VoiceInputMode.pushToTalk:
        return 'push_to_talk';
      case VoiceInputMode.voiceActivation:
        return 'voice_activation';
    }
  }

  String get displayName {
    switch (this) {
      case VoiceInputMode.pushToTalk:
        return 'Push-to-Talk';
      case VoiceInputMode.voiceActivation:
        return 'Sprachaktivierung';
    }
  }

  static VoiceInputMode fromString(String? value) {
    switch (value) {
      case 'voice_activation':
        return VoiceInputMode.voiceActivation;
      case 'push_to_talk':
      default:
        return VoiceInputMode.pushToTalk;
    }
  }
}

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

  // Voice Settings
  static VoiceInputMode getVoiceInputMode() {
    final value = prefs.getString(AppConfig.keyVoiceInputMode);
    return VoiceInputModeExtension.fromString(value);
  }
  static Future<void> setVoiceInputMode(VoiceInputMode mode) =>
      prefs.setString(AppConfig.keyVoiceInputMode, mode.value);

  static String getTranscriptionLanguage() =>
      prefs.getString(AppConfig.keyTranscriptionLanguage) ?? 'de_DE';
  static Future<void> setTranscriptionLanguage(String lang) =>
      prefs.setString(AppConfig.keyTranscriptionLanguage, lang);

  static double getPlaybackSpeed() =>
      prefs.getDouble(AppConfig.keyPlaybackSpeed) ?? 1.0;
  static Future<void> setPlaybackSpeed(double speed) =>
      prefs.setDouble(AppConfig.keyPlaybackSpeed, speed);

  static bool getAutoPlayVoice() =>
      prefs.getBool(AppConfig.keyAutoPlayVoice) ?? true;
  static Future<void> setAutoPlayVoice(bool value) =>
      prefs.setBool(AppConfig.keyAutoPlayVoice, value);

  static double getVoiceSensitivity() =>
      prefs.getDouble(AppConfig.keyVoiceSensitivity) ?? 0.7;
  static Future<void> setVoiceSensitivity(double value) =>
      prefs.setDouble(AppConfig.keyVoiceSensitivity, value);

  static int getPauseDuration() =>
      prefs.getInt(AppConfig.keyPauseDuration) ?? 3;
  static Future<void> setPauseDuration(int seconds) =>
      prefs.setInt(AppConfig.keyPauseDuration, seconds);

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