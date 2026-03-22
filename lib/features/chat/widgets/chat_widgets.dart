import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isDark;
  final String? agentName;
  final DateTime timestamp;
  final bool showAgentName;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    required this.isDark,
    this.agentName,
    required this.timestamp,
    this.showAgentName = true,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if content is JSON or code
    final isJson = _isJson(content);
    final isCode = _isCode(content);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isUser ? AppSpacing.xl : AppSpacing.md,
          right: isUser ? AppSpacing.md : AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? AppColors.primary
              : (isDark ? AppColors.assistantBubbleDark : AppColors.assistantBubbleLight),
          borderRadius: BorderRadius.circular(AppRadius.large).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Name (for assistant messages)
            if (!isUser && agentName != null && showAgentName)
              Container(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        agentName!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Message Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isCode || isJson
                  ? _CodeBlock(
                      content: content,
                      isDark: isDark,
                      isJson: isJson,
                    )
                  : SelectableText(
                      content,
                      style: TextStyle(
                        color: isUser 
                            ? Colors.white 
                            : (isDark ? AppColors.textDark : AppColors.textLight),
                        height: 1.4,
                      ),
                    ),
            ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: (isUser ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)).withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isJson(String text) {
    try {
      json.decode(text);
      return text.trim().startsWith('{') || text.trim().startsWith('[');
    } catch (_) {
      return false;
    }
  }

  bool _isCode(String text) {
    // Simple detection for code blocks
    return text.contains('```') || 
           text.contains('function ') ||
           text.contains('def ') ||
           text.contains('class ') ||
           text.contains('const ') ||
           text.contains('let ') ||
           text.contains('var ') ||
           (text.contains('\n') && text.contains('  '));
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _CodeBlock extends StatelessWidget {
  final String content;
  final bool isDark;
  final bool isJson;

  const _CodeBlock({
    required this.content,
    required this.isDark,
    required this.isJson,
  });

  @override
  Widget build(BuildContext context) {
    // Format JSON if needed
    String displayContent = content;
    if (isJson) {
      try {
        final parsed = json.decode(content);
        displayContent = const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {
        // Keep original if parsing fails
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          displayContent,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: isDark ? AppColors.success : AppColors.primaryDark,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class ToolCallCard extends StatefulWidget {
  final String toolName;
  final String status; // 'running', 'success', 'failed'
  final double progress;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? response;
  final bool isDark;

  const ToolCallCard({
    super.key,
    required this.toolName,
    required this.status,
    this.progress = 0.0,
    this.parameters,
    this.response,
    required this.isDark,
  });

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  bool _isExpanded = false;

  Color get _statusColor {
    switch (widget.status) {
      case 'running':
        return AppColors.warning;
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case 'running':
        return Icons.play_circle_outline;
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: _statusColor.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              if (widget.parameters != null || widget.response != null) {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Tool Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Icon(
                          Icons.build,
                          size: 18,
                          color: _statusColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      
                      // Tool Name - Large and Prominent
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.toolName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark 
                                    ? AppColors.textDark 
                                    : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  _statusIcon,
                                  size: 12,
                                  color: _statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusText(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Expand/Collapse Icon
                      if (widget.parameters != null || widget.response != null)
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.isDark 
                                ? AppColors.textDarkSecondary 
                                : AppColors.textLightSecondary,
                          ),
                        ),
                    ],
                  ),
                  
                  // Progress Bar (when running)
                  if (widget.status == 'running' && widget.progress > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: widget.isDark 
                            ? AppColors.bgDark 
                            : AppColors.bgLight,
                        valueColor: AlwaysStoppedAnimation(_statusColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isDark 
                            ? AppColors.textDarkSecondary 
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (widget.status) {
      case 'running':
        return 'Wird ausgeführt...';
      case 'success':
        return 'Erfolgreich';
      case 'failed':
        return 'Fehlgeschlagen';
      default:
        return widget.status;
    }
  }

  Widget _buildExpandedContent() {
    if (widget.parameters == null && widget.response == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.isDark 
            ? AppColors.bgDark.withOpacity(0.5)
            : AppColors.bgLight.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.medium),
          bottomRight: Radius.circular(AppRadius.medium),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parameters Section
          if (widget.parameters != null && widget.parameters!.isNotEmpty) ...[
            _SectionTitle(
              title: '📥 Parameter',
              isDark: widget.isDark,
            ),
            const SizedBox(height: AppSpacing.xs),
            _JsonViewer(
              data: widget.parameters!,
              isDark: widget.isDark,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Response/Output Section
          if (widget.response != null && widget.response!.isNotEmpty) ...[
            _SectionTitle(
              title: '📤 ${widget.status == 'failed' ? 'Fehler' : 'Ausgabe'}',
              isDark: widget.isDark,
              isError: widget.status == 'failed',
            ),
            const SizedBox(height: AppSpacing.xs),
            _JsonViewer(
              data: widget.response!,
              isDark: widget.isDark,
              isError: widget.status == 'failed',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final bool isError;

  const _SectionTitle({
    required this.title,
    required this.isDark,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isError 
            ? AppColors.error 
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
    );
  }
}

class _JsonViewer extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final bool isError;

  const _JsonViewer({
    required this.data,
    required this.isDark,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    String formatted;
    try {
      formatted = const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      formatted = data.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: isError 
            ? Border.all(color: AppColors.error.withOpacity(0.3))
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          formatted,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: isError 
                ? AppColors.error 
                : (isDark ? AppColors.textDark : AppColors.textLight),
            height: 1.4,
          ),
        ),
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulsing animation for the main dot
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
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
        color: widget.isDark 
            ? AppColors.bgDarkTertiary 
            : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing main dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(_pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(_pulseAnimation.value * 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Animated dots
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = (_dotsController.value + delay) % 1.0;
                final opacity = 0.3 + 0.7 * ((value < 0.5 ? value * 2 : 2 - value * 2));
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
          
          const SizedBox(width: AppSpacing.md),
          
          // "OpenClaw denkt nach..." text
          Text(
            'OpenClaw denkt nach',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDark 
                  ? AppColors.textDarkSecondary 
                  : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(String)? onImageSelected;
  final bool enabled;
  final bool showVoiceInput;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onImageSelected,
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
                onPressed: widget.enabled
                    ? () {
                        setState(() {
                          _isRecording = !_isRecording;
                        });
                      }
                    : null,
                tooltip: _isRecording ? 'Stop recording' : 'Voice input',
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !_isRecording,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _isRecording 
                      ? 'Listening...' 
                      : 'Nachricht eingeben...',
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
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: widget.enabled ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
