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

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final bool showVoiceInput;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.showVoiceInput = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _isRecording = false;

  @override
  void dispose() {
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

  void _toggleVoiceInput() {
    setState(() {
      _isRecording = !_isRecording;
    });
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
        child: Row(
          children: [
            if (widget.showVoiceInput)
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? AppColors.error : AppColors.primary,
                ),
                onPressed: widget.enabled ? _toggleVoiceInput : null,
              ),
            Expanded(
              child: TextField(
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
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: widget.enabled ? AppColors.primary : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.send,
                  color: Colors.white,
                ),
                onPressed: widget.enabled 
                    ? (_isRecording ? _toggleVoiceInput : _send)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
