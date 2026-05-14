import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppClipboard {
  /// Copy text to clipboard
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Get text from clipboard
  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Copy with feedback
  static Future<void> copyWithFeedback(BuildContext context, String text, {String? message}) async {
    await copy(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Kopiert!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class AppShare {
  /// Share text to other apps
  static Future<void> share(String text) async {
    // In a real app, use share_plus package
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share message with type
  static Future<void> shareMessage(String content, {String? sender}) async {
    final text = sender != null 
        ? '$sender: $content' 
        : content;
    await share(text);
  }
}

class AppLaunch {
  /// Open URL in browser
  static Future<void> openUrl(String url) async {
    // Use url_launcher package in real app
  }

  /// Open settings
  static Future<void> openSettings() async {
    // Use app_settings package in real app
  }

  /// Open phone dialer
  static Future<void> dialPhone(String number) async {
    // Use url_launcher package
  }

  /// Send email
  static Future<void> sendEmail(String email) async {
    // Use url_launcher package
  }
}

class AppExit {
  /// Exit app completely
  static void exit() {
    SystemNavigator.pop();
  }

  /// Minimize to background
  static void minimize() {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
