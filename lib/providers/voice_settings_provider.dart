import 'package:flutter/material.dart';
import '../core/constants/app_config.dart';
import '../core/services/local_storage.dart';

/// VoiceSettingsProvider - Manages voice input/output settings
/// Provides reactive state for voice settings across the app
class VoiceSettingsProvider extends ChangeNotifier {
  // Voice Input Mode (push-to-talk vs voice activation)
  VoiceInputMode _inputMode = VoiceInputMode.pushToTalk;
  VoiceInputMode get inputMode => _inputMode;

  // Transcription language
  String _transcriptionLanguage = 'de_DE';
  String get transcriptionLanguage => _transcriptionLanguage;

  // Playback speed (0.5 - 2.0)
  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  // Auto-play voice messages
  bool _autoPlayVoice = true;
  bool get autoPlayVoice => _autoPlayVoice;

  // Voice sensitivity (0.1 - 1.0)
  double _voiceSensitivity = 0.7;
  double get voiceSensitivity => _voiceSensitivity;

  // Pause duration in seconds
  int _pauseDuration = 3;
  int get pauseDuration => _pauseDuration;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  VoiceSettingsProvider() {
    _loadSettings();
  }

  /// Load all settings from LocalStorage
  void _loadSettings() {
    _inputMode = LocalStorage.getVoiceInputMode();
    _transcriptionLanguage = LocalStorage.getTranscriptionLanguage();
    _playbackSpeed = LocalStorage.getPlaybackSpeed();
    _autoPlayVoice = LocalStorage.getAutoPlayVoice();
    _voiceSensitivity = LocalStorage.getVoiceSensitivity();
    _pauseDuration = LocalStorage.getPauseDuration();
    _isLoading = false;
    notifyListeners();
  }

  /// Set voice input mode
  Future<void> setInputMode(VoiceInputMode mode) async {
    _inputMode = mode;
    await LocalStorage.setVoiceInputMode(mode);
    notifyListeners();
  }

  /// Set transcription language
  Future<void> setTranscriptionLanguage(String lang) async {
    _transcriptionLanguage = lang;
    await LocalStorage.setTranscriptionLanguage(lang);
    notifyListeners();
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await LocalStorage.setPlaybackSpeed(_playbackSpeed);
    notifyListeners();
  }

  /// Set auto-play voice messages
  Future<void> setAutoPlayVoice(bool value) async {
    _autoPlayVoice = value;
    await LocalStorage.setAutoPlayVoice(value);
    notifyListeners();
  }

  /// Set voice sensitivity
  Future<void> setVoiceSensitivity(double value) async {
    _voiceSensitivity = value.clamp(0.1, 1.0);
    await LocalStorage.setVoiceSensitivity(_voiceSensitivity);
    notifyListeners();
  }

  /// Set pause duration
  Future<void> setPauseDuration(int seconds) async {
    _pauseDuration = seconds.clamp(1, 10);
    await LocalStorage.setPauseDuration(_pauseDuration);
    notifyListeners();
  }

  /// Get available transcription languages
  static List<Map<String, String>> get availableLanguages => [
    {'code': 'de_DE', 'name': 'Deutsch'},
    {'code': 'en_US', 'name': 'English (US)'},
    {'code': 'en_GB', 'name': 'English (UK)'},
    {'code': 'es_ES', 'name': 'Español'},
    {'code': 'fr_FR', 'name': 'Français'},
    {'code': 'it_IT', 'name': 'Italiano'},
    {'code': 'pt_BR', 'name': 'Português (Brasil)'},
    {'code': 'zh_CN', 'name': '中文 (简体)'},
    {'code': 'ja_JP', 'name': '日本語'},
  ];

  /// Get language name for current code
  String get transcriptionLanguageName {
    final lang = availableLanguages.firstWhere(
      (l) => l['code'] == _transcriptionLanguage,
      orElse: () => {'code': _transcriptionLanguage, 'name': _transcriptionLanguage},
    );
    return lang['name'] ?? _transcriptionLanguage;
  }

  /// Get display name for sensitivity
  String get sensitivityLabel {
    if (_voiceSensitivity < 0.3) return 'Niedrig';
    if (_voiceSensitivity < 0.7) return 'Mittel';
    return 'Hoch';
  }

  /// Get display name for pause duration
  String get pauseDurationLabel {
    return '$_pauseDuration ${_pauseDuration == 1 ? 'Sekunde' : 'Sekunden'}';
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await setInputMode(VoiceInputMode.pushToTalk);
    await setTranscriptionLanguage('de_DE');
    await setPlaybackSpeed(1.0);
    await setAutoPlayVoice(true);
    await setVoiceSensitivity(0.7);
    await setPauseDuration(3);
  }
}