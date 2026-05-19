import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? AppSpacing.xl : AppSpacing.md,
          right: isUser ? AppSpacing.md : AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser 
              ? AppColors.primary
              : (isDark ? AppColors.assistantBubbleDark : AppColors.assistantBubbleLight),
          borderRadius: BorderRadius.circular(AppRadius.large).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.agentName != null && !isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  message.agentName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isUser 
                    ? Colors.white 
                    : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: (isUser ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ToolCallCard extends StatelessWidget {
  final Map<String, dynamic> toolData;
  final bool isDark;

  const ToolCallCard({
    super.key,
    required this.toolData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final toolName = toolData['tool'] ?? 'Unknown';
    final status = toolData['status'] ?? 'running';
    final progress = (toolData['progress'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: status == 'running' 
              ? AppColors.warning.withOpacity(0.5)
              : status == 'success'
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.error.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'running' 
                    ? Icons.play_circle_outline
                    : status == 'success'
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                size: 18,
                color: status == 'running' 
                    ? AppColors.warning
                    : status == 'success'
                        ? AppColors.success
                        : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                toolName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const Spacer(),
              if (status == 'running' && progress > 0)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
            ],
          ),
          if (status == 'running' && progress > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class ThinkingIndicator extends StatefulWidget {
  final bool isDark;

  const ThinkingIndicator({super.key, required this.isDark});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(
                    0.3 + 0.7 * ((_controller.value + index / 3) % 1),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/voice_recorder_service.dart';
import '../../../core/services/voice_message_service.dart';
import '../../../models/message.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final bool showVoiceInput;
  final VoiceRecorderService? recorderService;
  final VoiceMessageService? playbackService;
  final Function(String path)? onVoiceSend;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.showVoiceInput = true,
    this.recorderService,
    this.playbackService,
    this.onVoiceSend,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  
  // Voice animation
  late AnimationController _voiceAnimController;
  late Animation<double> _voiceAnimation;
  
  // Services
  VoiceRecorderService? _recorder;
  VoiceMessageService? _playback;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorderService;
    _playback = widget.playbackService;
    
    // Setup voice animation
    _voiceAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _voiceAnimController, curve: Curves.easeInOut),
    );
    
    // Listen to recorder updates
    _recorder?.addListener(_onRecorderUpdate);
  }

  void _onRecorderUpdate() {
    if (!mounted || _recorder == null) return;
    setState(() {
      _isRecording = _recorder!.isRecording;
      _recordingDuration = _recorder!.recordingDuration;
    });
    
    if (_isRecording && !_voiceAnimController.isAnimating) {
      _voiceAnimController.repeat(reverse: true);
    } else if (!_isRecording && _voiceAnimController.isAnimating) {
      _voiceAnimController.stop();
      _voiceAnimController.reset();
    }
  }

  @override
  void dispose() {
    _recorder?.removeListener(_onRecorderUpdate);
    _voiceAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_recorder == null) {
      // Fallback: placeholder
      setState(() => _isRecording = !_isRecording);
      if (_isRecording) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isRecording) {
            setState(() {
              _isRecording = false;
              _controller.text = "Voice input placeholder";
            });
          }
        });
      }
      return;
    }

    if (_isRecording) {
      // Stop recording
      final path = await _recorder!.stopRecording();
      if (path != null && widget.onVoiceSend != null) {
        widget.onVoiceSend!(path);
      }
      setState(() => _isRecording = false);
    } else {
      // Start recording
      final success = await _recorder!.startRecording();
      if (success) {
        setState(() => _isRecording = true);
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording indicator
            if (_isRecording) _buildRecordingIndicator(isDark),
            
            // Main input row
            Row(
              children: [
                if (widget.showVoiceInput) _buildVoiceButton(isDark),
                Expanded(child: _buildTextField(isDark)),
                const SizedBox(width: AppSpacing.sm),
                _buildSendButton(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          AnimatedBuilder(
            animation: _voiceAnimation,
            builder: (context, child) => Transform.scale(
              scale: _voiceAnimation.value,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Duration timer
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Waveform (simplified bars)
          SizedBox(
            height: 20,
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _voiceAnimController,
                  builder: (context, child) {
                    final height = 4 + (8 * (0.5 + 0.5 * _voiceAnimation.value));
                    return Container(
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(bool isDark) {
    return AnimatedBuilder(
      animation: _voiceAnimation,
      builder: (context, child) {
        final scale = _isRecording ? _voiceAnimation.value : 1.0;
        final color = _isRecording ? AppColors.error : AppColors.primary;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecording ? Iconsax.stop_circle : Iconsax.microphone,
                color: color,
              ),
              onPressed: widget.enabled ? _toggleVoiceInput : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled && !_isRecording,
      maxLines: 5,
      minLines: 1,
      decoration: InputDecoration(
        hintText: _isRecording ? 'Sprich jetzt...' : 'Nachricht eingeben...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      onSubmitted: (_) => _send(),
    );
  }

  Widget _buildSendButton(bool isDark) {
    final isActive = widget.enabled && (_controller.text.isNotEmpty || _isRecording);
    
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isRecording ? Iconsax.send_square : Iconsax.paper_plane,
          color: Colors.white,
        ),
        onPressed: isActive 
            ? (_isRecording ? _toggleVoiceInput : _send)
            : null,
      ),
    );
  }
}
