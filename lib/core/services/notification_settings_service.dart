import 'package:shared_preferences/shared_preferences.dart';

/// NotificationSettingsService - Local storage for notification preferences
/// 
/// Stores notification settings persistently using SharedPreferences.
/// Used by NotificationQuickSheet and settings screen.
class NotificationSettingsService {
  static const String _keyNotificationsEnabled = 'notif_enabled';
  static const String _keySoundEnabled = 'notif_sound';
  static const String _keyVibrationEnabled = 'notif_vibration';
  static const String _keyAgentOnly = 'notif_agent_only';
  static const String _keyQuietHoursEnabled = 'notif_quiet_hours_enabled';
  static const String _keyQuietHoursStart = 'notif_quiet_hours_start';
  static const String _keyQuietHoursEnd = 'notif_quiet_hours_end';

  // Default values
  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const bool _defaultAgentOnly = false;
  static const bool _defaultQuietHoursEnabled = false;
  static const int _defaultQuietHoursStart = 22; // 22:00
  static const int _defaultQuietHoursEnd = 8;    // 08:00

  // ========== Getters ==========

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<bool> getNotificationsEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyNotificationsEnabled) ?? _defaultNotificationsEnabled;
  }

  static Future<bool> getSoundEnabled() async {
    final p = await _prefs;
    return p.getBool(_keySoundEnabled) ?? _defaultSoundEnabled;
  }

  static Future<bool> getVibrationEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyVibrationEnabled) ?? _defaultVibrationEnabled;
  }

  static Future<bool> getAgentOnly() async {
    final p = await _prefs;
    return p.getBool(_keyAgentOnly) ?? _defaultAgentOnly;
  }

  static Future<bool> getQuietHoursEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyQuietHoursEnabled) ?? _defaultQuietHoursEnabled;
  }

  static Future<int> getQuietHoursStart() async {
    final p = await _prefs;
    return p.getInt(_keyQuietHoursStart) ?? _defaultQuietHoursStart;
  }

  static Future<int> getQuietHoursEnd() async {
    final p = await _prefs;
    return p.getInt(_keyQuietHoursEnd) ?? _defaultQuietHoursEnd;
  }

  // ========== Setters ==========

  static Future<void> setNotificationsEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(_keyNotificationsEnabled, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(_keySoundEnabled, value);
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(_keyVibrationEnabled, value);
  }

  static Future<void> setAgentOnly(bool value) async {
    final p = await _prefs;
    await p.setBool(_keyAgentOnly, value);
  }

  static Future<void> setQuietHoursEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(_keyQuietHoursEnabled, value);
  }

  static Future<void> setQuietHoursStart(int hour) async {
    final p = await _prefs;
    await p.setInt(_keyQuietHoursStart, hour);
  }

  static Future<void> setQuietHoursEnd(int hour) async {
    final p = await _prefs;
    await p.setInt(_keyQuietHoursEnd, hour);
  }

  // ========== Quiet Hours Logic ==========

  /// Check if current time is within quiet hours
  static Future<bool> isInQuietHours() async {
    final enabled = await getQuietHoursEnabled();
    if (!enabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    
    final startHour = await getQuietHoursStart();
    final endHour = await getQuietHoursEnd();

    // Handle overnight quiet hours (e.g., 22:00 - 08:00)
    if (startHour > endHour) {
      // Quiet hours span midnight
      return currentHour >= startHour || currentHour < endHour;
    } else {
      // Same day range (e.g., 13:00 - 15:00)
      return currentHour >= startHour && currentHour < endHour;
    }
  }

  /// Get quiet hours status as a formatted string
  static Future<String> getQuietHoursStatus() async {
    final enabled = await getQuietHoursEnabled();
    if (!enabled) return 'Aus';

    final startHour = await getQuietHoursStart();
    final endHour = await getQuietHoursEnd();
    
    final startStr = '${startHour.toString().padLeft(2, '0')}:00';
    final endStr = '${endHour.toString().padLeft(2, '0')}:00';

    return '$startStr – $endStr';
  }

  /// Get human-readable label for quiet hours
  static String getQuietHoursLabel(int startHour, int endHour) {
    final startStr = '${startHour.toString().padLeft(2, '0')}:00';
    final endStr = '${endHour.toString().padLeft(2, '0')}:00';
    return 'Stumm $startStr – $endStr';
  }
}
