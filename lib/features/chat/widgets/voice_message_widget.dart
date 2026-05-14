import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/voice_recorder_service.dart';
import '../../../core/services/voice_message_service.dart';
import '../../../providers/voice_settings_provider.dart';
import '../../settings/settings_screen.dart';

/// VoiceMessageWidget - Recording and playback UI for voice messages
/// 
/// Features:
/// - Recording mode with waveform visualization
/// - Playback mode with progress bar and controls
/// - Timer display during recording
/// - Send/Cancel buttons
class VoiceMessageWidget extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final VoiceMessageService playbackService;
  final String? initialRecordingPath; // For playback of existing message
  final Function(String path) onSend;
  final VoidCallback onCancel;
  final bool isCompact; // Compact mode for inline in chat

  const VoiceMessageWidget({
    super.key,
    required this.recorderService,
    required this.playbackService,
    this.initialRecordingPath,
    required this.onSend,
    required this.onCancel,
    this.isCompact = false,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with TickerProviderStateMixin {
  late VoiceRecorderService _recorder;
  late VoiceMessageService _playback;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  
  // Waveform animation
  late AnimationController _waveformController;
  late List<Animation<double>> _waveformAnimations;
  
  // Pulsing dot for recording
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorderService;
    _playback = widget.playbackService;
    
    _recorder.addListener(_onRecorderUpdate);
    _playback.addListener(_onPlaybackUpdate);
    
    _initWaveformAnimations();
    _initPulseAnimation();
    
    // If we have an initial path, set up for playback
    if (widget.initialRecordingPath != null) {
      _loadAudioDuration(widget.initialRecordingPath!);
    }
  }

  void _initWaveformAnimations() {
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Create 12 bars with different phases
    _waveformAnimations = List.generate(12, (index) {
      final phase = index * 0.15;
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveformController,
          curve: Interval(phase, 1.0, curve: Curves.easeInOut),
        ),
      );
    });
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onRecorderUpdate() {
    if (!mounted) return;
    setState(() {
      _isRecording = _recorder.isRecording;
      _recordingDuration = _recorder.recordingDuration;
    });
    
    // Control waveform animation based on recording state
    if (_isRecording && !_waveformController.isAnimating) {
      _waveformController.repeat(reverse: true);
    } else if (!_isRecording && _waveformController.isAnimating) {
      _waveformController.stop();
      _waveformController.reset();
    }
  }

  void _onPlaybackUpdate() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _playback.isPlaying;
      _playbackPosition = _playback.playbackPosition;
      _playbackDuration = _playback.playbackDuration;
    });
  }

  Future<void> _loadAudioDuration(String path) async {
    // Duration will be updated when playback starts
  }

  @override
  void dispose() {
    _recorder.removeListener(_onRecorderUpdate);
    _playback.removeListener(_onPlaybackUpdate);
    _waveformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    final success = await _recorder.startRecording();
    if (success) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecording();
    if (path != null && mounted) {
      widget.onSend(path);
    }
    setState(() => _isRecording = false);
  }

  Future<void> _cancelRecording() async {
    await _recorder.cancelRecording();
    widget.onCancel();
    setState(() => _isRecording = false);
  }

  Future<void> _playPause() async {
    if (widget.initialRecordingPath == null) return;
    
    if (_isPlaying) {
      await _playback.pausePlayback();
    } else {
      await _playback.playAudio(widget.initialRecordingPath!);
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(
      milliseconds: (value * _playbackDuration.inMilliseconds).round(),
    );
    await _playback.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voiceSettings = context.watch<VoiceSettingsProvider>();
    
    return Container(
      padding: EdgeInsets.all(
        widget.isCompact ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: _isRecording 
              ? AppColors.error.withOpacity(0.3) 
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: widget.isCompact 
          ? _buildCompactView(isDark, voiceSettings)
          : _buildFullView(isDark, voiceSettings),
    );
  }

  Widget _buildCompactView(bool isDark, VoiceSettingsProvider voiceSettings) {
    if (widget.initialRecordingPath != null) {
      // Playback mode for received voice messages
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Iconsax.pause : Iconsax.play,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Progress bar and duration
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: _playbackDuration.inMilliseconds > 0
                        ? _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds
                        : 0,
                    onChanged: _seekTo,
                  ),
                ),
                // Duration text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Recording mode - compact
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated recording indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(_pulseAnimation.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Timer
        Text(
          _formatDuration(_recordingDuration),
          style: AppTypography.bodySmall.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Waveform bars (mini)
        SizedBox(
          height: 24,
          width: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _waveformAnimations[index],
                builder: (context, child) {
                  final height = _isRecording 
                      ? 8 + (_waveformAnimations[index].value * 16)
                      : 8.0;
                  return Container(
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFullView(bool isDark, VoiceSettingsProvider voiceSettings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with mode indicator
        Row(
          children: [
            // Mode icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_isRecording ? AppColors.error : AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                _isRecording ? Iconsax.microphone_slash : Iconsax.microphone,
                color: _isRecording ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Mode text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRecording 
                        ? 'Aufnahme läuft...'
                        : (widget.initialRecordingPath != null 
                            ? 'Sprachnachricht' 
                            : 'Aufnahme starten'),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  Text(
                    widget.initialRecordingPath != null 
                        ? '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}'
                        : _formatDuration(_recordingDuration),
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Playback speed for received messages
            if (widget.initialRecordingPath != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  '${voiceSettings.playbackSpeed.toStringAsFixed(1)}x',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Waveform visualization (recording mode)
        if (_isRecording)
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(12, (index) {
                return AnimatedBuilder(
                  animation: _waveformAnimations[index],
                  builder: (context, child) {
                    final height = 8 + (_waveformAnimations[index].value * 40);
                    return Container(
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        
        // Playback progress bar
        if (widget.initialRecordingPath != null && !_isRecording)
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: _playbackDuration.inMilliseconds > 0
                      ? (_playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: _seekTo,
                ),
              ),
              // Playback time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_playbackPosition),
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    Text(
                      _formatDuration(_playbackDuration),
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _isRecording
              ? [
                  // Cancel button
                  _ControlButton(
                    icon: Iconsax.close_square,
                    label: 'Abbrechen',
                    color: AppColors.textLightSecondary,
                    onTap: _cancelRecording,
                  ),
                  // Stop/Send button
                  _ControlButton(
                    icon: Iconsax.send_square,
                    label: 'Senden',
                    color: AppColors.success,
                    onTap: _stopRecording,
                  ),
                ]
              : [
                  // Play/Pause for received messages
                  if (widget.initialRecordingPath != null)
                    GestureDetector(
                      onTap: _playPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Iconsax.pause : Iconsax.play,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  // Start recording
                  if (widget.initialRecordingPath == null)
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.microphone,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
        ),
      ],
    );
  }
}

/// Individual control button for voice message widget
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Inline voice message indicator for chat bubbles
class VoiceMessageIndicator extends StatelessWidget {
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onTap;

  const VoiceMessageIndicator({
    super.key,
    required this.duration,
    required this.isPlaying,
    required this.onTap,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated indicator when playing
            if (isPlaying)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              Icon(
                Icons.mic,
                size: 18,
                color: isDark ? Colors.white70 : AppColors.primary,
              ),
            const SizedBox(width: AppSpacing.sm),
            // Duration text
            Text(
              _formatDuration(duration),
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Play icon hint
            Icon(
              isPlaying ? Iconsax.pause : Iconsax.play,
              size: 16,
              color: isDark ? Colors.white54 : AppColors.textLightSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
