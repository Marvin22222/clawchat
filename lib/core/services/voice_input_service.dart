import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceInputService extends ChangeNotifier {
  bool _isListening = false;
  String _transcribedText = '';
  bool _isAvailable = false;

  bool get isListening => _isListening;
  String get transcribedText => _transcribedText;
  bool get isAvailable => _isAvailable;

  VoiceInputService() {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    // On iOS, we'd check platform availability
    // For now, assume it's available on mobile platforms
    _isAvailable = Platform.isIOS || Platform.isAndroid;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _transcribedText = '';
    notifyListeners();

    // In a real implementation, this would use speech_to_text package
    // For now, we'll simulate the functionality
    try {
      // Placeholder for actual speech recognition
      // Using method channel to native iOS/Android speech recognition
    } catch (e) {
      debugPrint('Voice input error: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    notifyListeners();
  }

  void cancelListening() {
    _isListening = false;
    _transcribedText = '';
    notifyListeners();
  }
}
