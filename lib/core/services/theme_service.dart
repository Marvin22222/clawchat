import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  dark('Dunkel', 'Standard dark theme'),
  light('Hell', 'Classic light theme'),
  oledBlack('OLED Schwarz', 'Pure black for OLED displays'),
  purple('Lila', 'Dark purple theme'),
  ocean('Ozean', 'Deep blue ocean theme'),
  forest('Wald', 'Nature green theme'),
  sunset('Sunset', 'Warm orange theme');

  final String label;
  final String description;
  const AppThemeType(this.label, this.description);
}

enum AccentColorType {
  indigo('Indigo', Color(0xFF10A37F)),
  blue('Blau', Color(0xFF3B82F6)),
  purple('Lila', Color(0xFF8B5CF6)),
  pink('Pink', Color(0xFFEC4899)),
  red('Rot', Color(0xFFEF4444)),
  orange('Orange', Color(0xFFF59E0B)),
  teal('Teal', Color(0xFF14B8A6)),
  green('Grün', Color(0xFF10B981));

  final String label;
  final Color color;
  const AccentColorType(this.label, this.color);
}

class ThemeService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme mode (dark/light/system)
  static ThemeMode getThemeMode() {
    final modeIndex = _prefs?.getInt('theme_mode') ?? 0;
    switch (modeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    int index;
    switch (mode) {
      case ThemeMode.light:
        index = 1;
        break;
      case ThemeMode.system:
        index = 2;
        break;
      default:
        index = 0;
    }
    await _prefs?.setInt('theme_mode', index);
  }

  // Theme type (dark, oled, purple, ocean, etc.)
  static AppThemeType getThemeType() {
    final typeIndex = _prefs?.getInt('theme_type') ?? 0;
    if (typeIndex >= 0 && typeIndex < AppThemeType.values.length) {
      return AppThemeType.values[typeIndex];
    }
    return AppThemeType.dark;
  }

  static Future<void> setThemeType(AppThemeType type) async {
    await _prefs?.setInt('theme_type', type.index);
  }

  // Accent color
  static AccentColorType getAccentColor() {
    final colorIndex = _prefs?.getInt('accent_color_type') ?? 0;
    if (colorIndex >= 0 && colorIndex < AccentColorType.values.length) {
      return AccentColorType.values[colorIndex];
    }
    return AccentColorType.indigo;
  }

  static Future<void> setAccentColor(AccentColorType color) async {
    await _prefs?.setInt('accent_color_type', color.index);
  }

  // Get complete theme colors based on type and mode
  static AppColorsData getAppColors(AppThemeType type, bool isDark) {
    switch (type) {
      case AppThemeType.oledBlack:
        return AppColorsData(
          background: const Color(0xFF000000),
          backgroundSecondary: const Color(0xFF0A0A0A),
          backgroundTertiary: const Color(0xFF141414),
          surface: const Color(0xFF000000),
          text: Colors.white,
          textSecondary: const Color(0xFF8B8B8B),
          primary: isDark ? const Color(0xFF10A37F) : const Color(0xFF10A37F),
        );
      case AppThemeType.purple:
        return AppColorsData(
          background: const Color(0xFF1A1025),
          backgroundSecondary: const Color(0xFF251535),
          backgroundTertiary: const Color(0xFF301A45),
          surface: const Color(0xFF1A1025),
          text: Colors.white,
          textSecondary: const Color(0xFFB8A8C8),
          primary: const Color(0xFF9333EA),
        );
      case AppThemeType.ocean:
        return AppColorsData(
          background: const Color(0xFF0A1628),
          backgroundSecondary: const Color(0xFF0F1F35),
          backgroundTertiary: const Color(0xFF142842),
          surface: const Color(0xFF0A1628),
          text: Colors.white,
          textSecondary: const Color(0xFF7BA3C0),
          primary: const Color(0xFF0EA5E9),
        );
      case AppThemeType.forest:
        return AppColorsData(
          background: const Color(0xFF0A1A0A),
          backgroundSecondary: const Color(0xFF0F250F),
          backgroundTertiary: const Color(0xFF143014),
          surface: const Color(0xFF0A1A0A),
          text: Colors.white,
          textSecondary: const Color(0xFF7BB87A),
          primary: const Color(0xFF22C55E),
        );
      case AppThemeType.sunset:
        return AppColorsData(
          background: const Color(0xFF1A1010),
          backgroundSecondary: const Color(0xFF251515),
          backgroundTertiary: const Color(0xFF301A1A),
          surface: const Color(0xFF1A1010),
          text: Colors.white,
          textSecondary: const Color(0xFFC88B8B),
          primary: const Color(0xFFEF4444),
        );
      case AppThemeType.light:
        return AppColorsData(
          background: Colors.white,
          backgroundSecondary: const Color(0xFFF4F4F5),
          backgroundTertiary: const Color(0xFFE4E4E7),
          surface: Colors.white,
          text: const Color(0xFF18181B),
          textSecondary: const Color(0xFF71717A),
          primary: const Color(0xFF10A37F),
        );
      default: // dark
        return AppColorsData(
          background: const Color(0xFF0D0D0D),
          backgroundSecondary: const Color(0xFF171717),
          backgroundTertiary: const Color(0xFF1F1F1F),
          surface: const Color(0xFF0D0D0D),
          text: Colors.white,
          textSecondary: const Color(0xFF8B8B8B),
          primary: const Color(0xFF10A37F),
        );
    }
  }

  // Apply system UI overlay style based on theme
  static void applySystemUIOverlayStyle(AppThemeType type, bool isDark) {
    if (isDark) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0D0D0D),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }
}

class AppColorsData {
  final Color background;
  final Color backgroundSecondary;
  final Color backgroundTertiary;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color primary;

  AppColorsData({
    required this.background,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.primary,
  });
}