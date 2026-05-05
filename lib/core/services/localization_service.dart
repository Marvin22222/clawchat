import 'dart:convert';
import 'package:flutter/material.dart';

/// Localization service for internationalization
/// Supports English (default) and German
class LocalizationService {
  static const String _defaultLocale = 'en';
  static Map<String, dynamic>? _translations;
  static String _currentLocale = _defaultLocale;

  /// Initialize with device locale or default
  static Future<void> init() async {
    // Could detect device locale here
    _currentLocale = 'de'; // Default to German for now
    await _loadTranslations(_currentLocale);
  }

  /// Load translations for a locale
  static Future<void> _loadTranslations(String locale) async {
    try {
      // In a real app, would load from assets
      // For now, using embedded translations
      _translations = _getTranslations(locale);
    } catch (e) {
      _translations = _getTranslations(_defaultLocale);
    }
  }

  /// Get a translation by key
  static String translate(String key) {
    if (_translations == null) return key;
    return _translations![key] ?? key;
  }

  /// Change locale
  static void setLocale(String locale) {
    _currentLocale = locale;
    _loadTranslations(locale);
  }

  /// Get current locale
  static String get currentLocale => _currentLocale;

  /// Get embedded translations
  static Map<String, dynamic> _getTranslations(String locale) {
    switch (locale) {
      case 'de':
        return {
          "appTitle": "ClawChat",
          "settings": "Einstellungen",
          "connection": "Verbindung",
          "appearance": "Darstellung",
          "security": "Sicherheit",
          "voiceInput": "Spracheingabe",
          "agents": "Agents",
          "about": "Über",
          "online": "Online",
          "offline": "Offline",
          "connecting": "Verbinde...",
          "sendMessage": "Nachricht senden",
          "typeMessage": "Nachricht eingeben...",
          "voiceSensitivity": "Sprach-Empfindlichkeit",
          "exportChat": "Chat exportieren",
          "exportAsJson": "Als JSON exportieren",
          "exportAsText": "Als Text exportieren",
          "searchChat": "Chat durchsuchen",
          "editMessage": "Nachricht bearbeiten",
          "deleteMessage": "Nachricht löschen",
          "copyMessage": "Nachricht kopieren",
          "cancel": "Abbrechen",
          "save": "Speichern",
          "ok": "OK",
          "error": "Fehler",
          "success": "Erfolg",
        };
      default:
        return {
          "appTitle": "ClawChat",
          "settings": "Settings",
          "connection": "Connection",
          "appearance": "Appearance",
          "security": "Security",
          "voiceInput": "Voice Input",
          "agents": "Agents",
          "about": "About",
          "online": "Online",
          "offline": "Offline",
          "connecting": "Connecting...",
          "sendMessage": "Send message",
          "typeMessage": "Type a message...",
          "voiceSensitivity": "Voice Sensitivity",
          "exportChat": "Export Chat",
          "exportAsJson": "Export as JSON",
          "exportAsText": "Export as Text",
          "searchChat": "Search in chat",
          "editMessage": "Edit message",
          "deleteMessage": "Delete message",
          "copyMessage": "Copy message",
          "cancel": "Cancel",
          "save": "Save",
          "ok": "OK",
          "error": "Error",
          "success": "Success",
        };
    }
  }
}

/// Extension to get localized strings from BuildContext
extension LocalizationExtension on BuildContext {
  String l10n(String key) => LocalizationService.translate(key);
}
