import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/de.dart';
import '../l10n/en.dart';

/// Localization service for internationalization
/// Supports English (default) and German
class LocalizationService {
  static const String _keyLocale = 'app_locale';
  static Locale _currentLocale = const Locale('de');
  static String? _selectedMode; // 'system', 'de', 'en'

  /// Map of supported locales
  static const Map<String, Map<String, String>> _translations = {
    'de': de,
    'en': en,
  };

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('de'),
    Locale('en'),
  ];

  /// Initialize locale from SharedPreferences or system
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_keyLocale);
    
    if (savedLocale != null) {
      _selectedMode = savedLocale;
      if (savedLocale == 'system') {
        _currentLocale = WidgetsBinding.instance.platformDispatcher.locale;
        // Fallback to German if system locale not supported
        if (!isSupported(_currentLocale)) {
          _currentLocale = const Locale('de');
        }
      } else {
        _currentLocale = Locale(savedLocale);
      }
    } else {
      // Default to German
      _selectedMode = 'de';
      _currentLocale = const Locale('de');
    }
  }

  /// Check if a locale is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Get current locale
  static Locale getCurrentLocale() => _currentLocale;

  /// Get current locale as string
  static String get currentLocaleCode => _currentLocale.languageCode;

  /// Get selected mode ('system', 'de', 'en')
  static String? get selectedMode => _selectedMode;

  /// Set locale by language code
  static Future<void> setLocale(String localeCode) async {
    _selectedMode = localeCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, localeCode);
    
    if (localeCode == 'system') {
      _currentLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (!isSupported(_currentLocale)) {
        _currentLocale = const Locale('de');
      }
    } else {
      _currentLocale = Locale(localeCode);
    }
  }

  /// Set locale by Locale object
  static Future<void> setLocaleByLocale(Locale locale) async {
    await setLocale(locale.languageCode);
  }

  /// Get list of supported locales
  static List<Locale> getSupportedLocales() => supportedLocales;

  /// Get a translation by key
  static String translate(String key) {
    final translations = _translations[_currentLocale.languageCode];
    if (translations == null) return key;
    return translations[key] ?? key;
  }

  /// Get language name for display
  static String getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      default:
        return localeCode;
    }
  }
}

/// Extension to get localized strings from BuildContext
extension LocalizationExtension on BuildContext {
  String l10n(String key) => LocalizationService.translate(key);
}