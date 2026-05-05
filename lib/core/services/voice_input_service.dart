import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../utils/logger.dart';

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
        AppLogger.debug('VoiceInputService: Nicht verfügbar', tag: 'STT');
      } else {
        AppLogger.debug('VoiceInputService: Initialisiert und bereit', tag: 'STT');
      }
      
      notifyListeners();
    } catch (e) {
      _isAvailable = false;
      _lastError = 'Initialisierungsfehler: $e';
      AppLogger.error('VoiceInputService initialization failed: $e', tag: 'STT');
      notifyListeners();
    }
  }

  /// Status Callback vom speech_to_text Package
  void _onStatus(String status) {
    AppLogger.debug('VoiceInputService Status: $status', tag: 'STT');
    
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
    AppLogger.error('VoiceInputService Error: $error', tag: 'STT');
    
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
      
      AppLogger.debug('VoiceInputService: Höre zu...', tag: 'STT');
    } catch (e) {
      _lastError = 'Fehler beim Starten: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Verarbeitet das Spracherkennungsergebnis
  void _onResult(SpeechRecognitionResult result) {
    _transcribedText = result.recognizedWords;
    
    AppLogger.debug('VoiceInputService Result: ${result.recognizedWords}', tag: 'STT');
    
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
      
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      
      AppLogger.debug('VoiceInputService: Gestoppt mit Text: $_transcribedText', tag: 'STT');
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
      
      AppLogger.debug('VoiceInputService: Abgebrochen', tag: 'STT');
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
