import 'package:flutter/material.dart';

class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

class AppDurations {
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration dialogDuration = Duration(minutes: 5);
  static const Duration toastDuration = Duration(seconds: 2);
}

class AppDimensions {
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Avatar sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 96.0;

  // Button sizes
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Card sizes
  static const double cardElevation = 2.0;
  static const double cardRadius = 12.0;

  // Input sizes
  static const double inputHeight = 48.0;
  static const double inputRadius = 12.0;

  // Bottom nav
  static const double bottomNavHeight = 80.0;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}

class AppStrings {
  // App
  static const String appName = 'ClawChat';
  static const String appVersion = '1.0.0';

  // Auth
  static const String login = 'Anmelden';
  static const String logout = 'Abmelden';
  static const String register = 'Registrieren';
  static const String forgotPassword = 'Passwort vergessen?';

  // Gateway
  static const String gatewayUrl = 'Gateway URL';
  static const String gatewayToken = 'Gateway Token';
  static const String connect = 'Verbinden';
  static const String disconnect = 'Trennen';

  // Chat
  static const String sendMessage = 'Nachricht senden';
  static const String typeMessage = 'Nachricht eingeben...';
  static const String noMessages = 'Keine Nachrichten';

  // Agents
  static const String agents = 'Agents';
  static const String selectAgent = 'Agent auswählen';
  static const String switchAgent = 'Agent wechseln';

  // Tasks
  static const String tasks = 'Aufgaben';
  static const String noTasks = 'Keine Aufgaben';

  // Settings
  static const String settings = 'Einstellungen';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String notifications = 'Benachrichtigungen';

  // Errors
  static const String error = 'Fehler';
  static const String errorOccurred = 'Ein Fehler ist aufgetreten';
  static const String tryAgain = 'Erneut versuchen';
  static const String cancel = 'Abbrechen';
  static const String ok = 'OK';

  // Success
  static const String success = 'Erfolgreich';
  static const String saved = 'Gespeichert';

  // Loading
  static const String loading = 'Laden...';
  static const String pleaseWait = 'Bitte warten...';
}
