import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// VoiceRecorderService - Records audio for voice messages
/// Uses the record package to capture audio in AAC/m4a format
class VoiceRecorderService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;

  /// Check if recording permission is granted
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      AppLogger.error('VoiceRecorderService: Permission check failed - $e', tag: 'RECORDER');
      return false;
    }
  }

  /// Start recording audio
  /// Returns true if recording started successfully
  Future<bool> startRecording() async {
    if (_isRecording) return false;
    
    try {
      // Check permission first
      if (!await hasPermission()) {
        AppLogger.warning('VoiceRecorderService: No permission to record', tag: 'RECORDER');
        return false;
      }
      
      // Get temporary directory for recording
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${dir.path}/voice_message_$timestamp.m4a';
      
      // Configure and start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _recordingStartTime = DateTime.now();
      _startDurationTimer();
      
      AppLogger.debug('VoiceRecorderService: Recording started - $_currentRecordingPath', tag: 'RECORDER');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('VoiceRecorderService: Start recording failed - $e', tag: 'RECORDER');
      _isRecording = false;
      return false;
    }
  }

  /// Start the duration timer for tracking recording time
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null && _isRecording) {
        _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// Stop recording and return the file path
  /// Returns null if not currently recording
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    
    _durationTimer?.cancel();
    
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      final resultPath = path ?? _currentRecordingPath;
      AppLogger.debug('VoiceRecorderService: Recording stopped - $resultPath', tag: 'RECORDER');
      notifyListeners();
      
      return resultPath;
    } catch (e) {
      AppLogger.error('VoiceRecorderService: Stop recording failed - $e', tag: 'RECORDER');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (e) {
        AppLogger.error('VoiceRecorderService: Cancel stop failed - $e', tag: 'RECORDER');
      }
    }
    
    // Delete the recording file
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          AppLogger.debug('VoiceRecorderService: Recording deleted - $_currentRecordingPath', tag: 'RECORDER');
        }
      } catch (e) {
        AppLogger.error('VoiceRecorderService: Delete file failed - $e', tag: 'RECORDER');
      }
    }
    
    _isRecording = false;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    _recordingStartTime = null;
    notifyListeners();
  }

  /// Check if recording file exists
  Future<bool> recordingExists() async {
    if (_currentRecordingPath == null) return false;
    return await File(_currentRecordingPath!).exists();
  }

  /// Get recording file size in bytes
  Future<int?> getRecordingSize() async {
    if (_currentRecordingPath == null) return null;
    try {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      AppLogger.error('VoiceRecorderService: Get size failed - $e', tag: 'RECORDER');
    }
    return null;
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}