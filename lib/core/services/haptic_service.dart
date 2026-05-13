import 'package:flutter/services.dart';
import 'dart:io';

/// Haptic feedback intensity levels
enum HapticIntensity { off, light, medium, heavy }

/// Service for haptic feedback on interactions
class HapticService {
  HapticService._();
  
  /// Current intensity setting (default: medium)
  static HapticIntensity _intensity = HapticIntensity.medium;
  
  /// Get current intensity
  static HapticIntensity get intensity => _intensity;
  
  /// Set haptic intensity
  static void setIntensity(HapticIntensity intensity) {
    _intensity = intensity;
  }
  
  /// Check if haptics are enabled
  static bool get isEnabled => _intensity != HapticIntensity.off;
  
  /// Light impact - for button taps, selections
  static void lightImpact() {
    if (!isEnabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.off:
        break;
    }
  }

  /// Medium impact - for important actions
  static void mediumImpact() {
    if (!isEnabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticIntensity.off:
        break;
    }
  }

  /// Heavy impact - for major events
  static void heavyImpact() {
    if (!isEnabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.heavyImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticIntensity.off:
        break;
    }
  }

  /// Selection click - for radio buttons, checkboxes
  static void selectionClick() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for errors or warnings
  static void vibrate() {
    if (!isEnabled) return;
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
  
  /// Reaction added feedback
  static void onReactionAdded() {
    lightImpact();
  }
  
  /// Long press menu opened feedback
  static void onContextMenuOpened() {
    mediumImpact();
  }
  
  /// Quick reaction picker opened feedback
  static void onQuickReactionOpened() {
    lightImpact();
  }
  
  /// Swipe action feedback
  static void onSwipeAction() {
    lightImpact();
  }
  
  /// Destructive action feedback
  static void onDestructiveAction() {
    heavyImpact();
  }
}