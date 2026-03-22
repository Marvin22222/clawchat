import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// VoiceInputService - Echte Speech-to-Text Implementierung
/// Nutzt das speech_to_text Package für plattformübergreifende Spracherkennung
class VoiceInputService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  
  bool _isListening = false;
  String _transcribedText = '';
  bool _isAvailable = false;
  String _lastError = '';
  
  bool get isListening => _isListening;
  String get transcribedText => _transcribedText;
  bool get isAvailable => _isAvailable;
  String get lastError => _lastError;

  VoiceInputService() {
    _init();
  }

  /// Initialisiert den Speech-to-Text Service
  Future<void> _init() async {
    try {
      // Prüfe ob Spracherkennung auf der Plattform verfügbar ist
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );
      
      if (!_isAvailable) {
        _lastError = 'Spracherkennung nicht verfügbar auf diesem Gerät';
        if (kDebugMode) {
          debugPrint('VoiceInputService: Nicht verfügbar');
        }
      } else {
        if (kDebugMode) {
          debugPrint('VoiceInputService: Initialisiert und bereit');
        }
      }
      
      notifyListeners();
    } catch (e) {
      _isAvailable = false;
      _lastError = 'Initialisierungsfehler: $e';
      if (kDebugMode) {
        debugPrint('VoiceInputService Error: $e');
      }
      notifyListeners();
    }
  }

  /// Status Callback vom speech_to_text Package
  void _onStatus(String status) {
    if (kDebugMode) {
      debugPrint('VoiceInputService Status: $status');
    }
    
    // Automatisch stoppen wenn nicht mehr aktiv
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _isListening = false;
        notifyListeners();
      }
    }
  }

  /// Fehler Callback vom speech_to_text Package
  void _onError(Object error) {
    if (kDebugMode) {
      debugPrint('VoiceInputService Error: $error');
    }
    
    _lastError = error.toString();
    _isListening = false;
    notifyListeners();
  }

  /// Startet die Spracherkennung
  Future<void> startListening() async {
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _transcribedText = '';
    _lastError = '';
    notifyListeners();

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 30), // Max 30 Sekunden
        pauseFor: const Duration(seconds: 3),   // Pause nach 3 Sekunden
        partialResults: true,                   // Teilergebnisse anzeigen
        cancelOnError: true,                    // Bei Fehler abbrechen
        listenMode: ListenMode.confirmation,
      );
      
      if (kDebugMode) {
        debugPrint('VoiceInputService: Höre zu...');
      }
    } catch (e) {
      _lastError = 'Fehler beim Starten: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Verarbeitet das Spracherkennungsergebnis
  void _onResult(SpeechRecognitionResult result) {
    _transcribedText = result.recognizedWords;
    
    if (kDebugMode) {
      debugPrint('VoiceInputService Result: ${result.recognizedWords}');
    }
    
    // Wenn finales Ergebnis und nicht mehr hören soll
    if (result.finalResult && _isListening) {
      _isListening = false;
    }
    
    notifyListeners();
  }

  /// Stoppt die Spracherkennung
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('VoiceInputService: Gestoppt mit Text: $_transcribedText');
      }
    } catch (e) {
      _lastError = 'Stopp-Fehler: $e';
      notifyListeners();
    }
  }

  /// Bricht die Spracherkennung ab
  Future<void> cancelListening() async {
    if (!_isListening && _transcribedText.isEmpty) return;
    
    try {
      await _speech.cancel();
      _isListening = false;
      _transcribedText = '';
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('VoiceInputService: Abgebrochen');
      }
    } catch (e) {
      _lastError = 'Cancel-Fehler: $e';
      notifyListeners();
    }
  }

  /// Setzt den transkribierten Text zurück
  void clearText() {
    _transcribedText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
