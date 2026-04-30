import 'package:flutter/services.dart';

/// Service for haptic feedback on interactions
class HapticService {
  HapticService._();

  /// Light impact - for button taps, selections
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for important actions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for major events
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for radio buttons, checkboxes
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for errors or warnings
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Convenience methods for specific use cases

  /// Button press feedback
  static void onButtonPress() {
    lightImpact();
  }

  /// Message sent feedback
  static void onMessageSent() {
    mediumImpact();
  }

  /// Error feedback
  static void onError() {
    vibrate();
  }

  /// Success feedback
  static void onSuccess() {
    mediumImpact();
  }

  /// Long press feedback
  static void onLongPress() {
    mediumImpact();
  }

  /// Recording start/stop feedback
  static void onRecordingToggle() {
    heavyImpact();
  }

  /// Voice message play/pause feedback
  static void onPlaybackToggle() {
    lightImpact();
  }
}