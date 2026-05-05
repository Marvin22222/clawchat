import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// VoiceMessageService - Records and plays back audio messages
/// Uses the record package for audio recording
class VoiceMessageService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _currentPlayingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;

  VoiceMessageService() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onPositionChanged.listen((position) {
      _playbackPosition = position;
      notifyListeners();
    });

    _player.onDurationChanged.listen((duration) {
      _playbackDuration = duration;
      notifyListeners();
    });
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${dir.path}/voice_message_$timestamp.m4a';

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
        notifyListeners();

        // Start duration timer
        _startRecordingTimer();

        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('VoiceMessageService: Start recording failed - $e', tag: 'VOICE');
      return false;
    }
  }

  DateTime? _recordingStartTime;

  void _startRecordingTimer() {
    _recordingStartTime = DateTime.now();
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      if (_recordingStartTime != null) {
        _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        notifyListeners();
      }
      return _isRecording;
    });
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _recordingDuration = Duration.zero;
      notifyListeners();

      return path ?? _currentRecordingPath;
    } catch (e) {
      AppLogger.error('VoiceMessageService: Stop recording failed - $e', tag: 'VOICE');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.error('VoiceMessageService: Cancel recording failed - $e', tag: 'VOICE');
    } finally {
      _isRecording = false;
      _currentRecordingPath = null;
      notifyListeners();
    }
  }

  /// Play audio from file path
  Future<void> playAudio(String path) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      _currentPlayingPath = path;
      await _player.play(DeviceFileSource(path));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('VoiceMessageService: Play audio failed - $e', tag: 'VOICE');
    }
  }

  /// Pause playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      AppLogger.error('VoiceMessageService: Pause failed - $e', tag: 'VOICE');
    }
  }

  /// Resume playback
  Future<void> resumePlayback() async {
    try {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('VoiceMessageService: Resume failed - $e', tag: 'VOICE');
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingPath = null;
      _playbackPosition = Duration.zero;
      notifyListeners();
    } catch (e) {
      AppLogger.error('VoiceMessageService: Stop playback failed - $e', tag: 'VOICE');
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      AppLogger.error('VoiceMessageService: Seek failed - $e', tag: 'VOICE');
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}