import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/helpers.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/voice_input_service.dart';
import '../../../core/services/voice_message_service.dart';
import '../../../models/message.dart';
import '../../../widgets/animations/app_transitions.dart';
import 'streaming_text.dart';
import 'fullscreen_image_viewer.dart';
import 'package:flutter/gestures.dart';
import '../../../widgets/animations/skeleton_loaders.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isDark;
  final String? agentName;
  final DateTime timestamp;
  final bool showAgentName;
  final List<MessageAttachment>? attachments;
  final MessageStatus? status;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? messageId;
  final Map<String, int>? reactions;
  final bool isStreaming; // true while text is being streamed
  final bool isEdited; // true if message was edited
  final Function(String emoji)? onReact; // Callback for double-tap reaction

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    required this.isDark,
    this.agentName,
    required this.timestamp,
    this.showAgentName = true,
    this.attachments,
    this.status,
    this.onRetry,
    this.onEdit,
    this.onDelete,
    this.messageId,
    this.reactions,
    this.isStreaming = false,
    this.isEdited = false,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if content is JSON or code
    final isJson = _isJson(content);
    final isCode = _isCode(content);

    return isUser && onDelete != null
        ? Dismissible(
          key: ValueKey(messageId ?? content),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Iconsax.trash, color: Colors.white),
          ),
          onDismissed: (_) => onDelete?.call(),
          child: Align(
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
              child: GestureDetector(
                onDoubleTap: () {
                  if (onReact != null) {
                    _showQuickReactionPicker(context);
                  }
                },
                onLongPress: () {
                  _showContextMenu(context);
                },
                child: isCode || isJson
                    ? _CodeBlock(
                        content: content,
                        isDark: isDark,
                        isJson: isJson,
                      )
                    : _InteractiveText(
                        content: content,
                        isUser: isUser,
                        isDark: isDark,
                        isStreaming: isStreaming,
                      ),
              ),
            ),
            
            // Attachment Preview
            if (attachments != null && attachments!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: _AttachmentRow(
                  attachments: attachments!,
                  isUser: isUser,
                  isDark: isDark,
                ),
              ),
            
            // Timestamp + Status
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time
                  Text(
                    DateTimeUtils.formatRelativeTime(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: (isUser ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)).withOpacity(0.6),
                    ),
                  ),
                  // Status indicator for user messages
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status == MessageStatus.error
                          ? Iconsax.warning_2_outline
                          : status == MessageStatus.sending
                              ? Iconsax.clock
                              : Iconsax.tick_circle,
                      size: 12,
                      color: status == MessageStatus.error
                          ? Colors.white70
                          : (status == MessageStatus.sending
                              ? Colors.white54
                              : Colors.white70),
                    ),
                  ],
                  if (reactions != null && reactions!.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ...reactions!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12)),
                          if (e.value > 1) ...[
                            const SizedBox(width: 2),
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isUser ? Colors.white70 : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
                  ],
                  if (status == MessageStatus.error) ...[
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: onRetry,
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.refresh,
                            size: 12,
                            color: isUser ? Colors.white70 : AppColors.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser ? Colors.white70 : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Edited indicator for user messages
                  if (isEdited) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '(bearbeitet)',
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: isUser ? Colors.white54 : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                  if (status == MessageStatus.sending) ...[
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUser ? Colors.white70 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
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

    }
  }

  void _showQuickReactionPicker(BuildContext context) {
    final reactions = ['👍', '❤️', '😂', '🔥', '✅'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Schnelle Reaktion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reactions.map((emoji) => 
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact?.call(emoji);
                      HapticService.lightImpact();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDark : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Copy option (always available)
              ListTile(
                leading: Icon(Iconsax.copy, color: isDark ? AppColors.textDark : AppColors.textLight),
                title: Text(
                  'Kopieren',
                  style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nachricht kopiert'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  HapticService.lightImpact();
                },
              ),
              // Edit option (only for user messages)
              if (isUser && onEdit != null) ...[
                ListTile(
                  leading: Icon(Iconsax.edit, color: AppColors.primary),
                  title: Text(
                    'Bearbeiten',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final editController = TextEditingController(text: content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: Text(
          'Nachricht bearbeiten',
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
        ),
        content: TextField(
          controller: editController,
          maxLines: 5,
          autofocus: true,
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Nachricht eingeben...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            filled: true,
            fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != content) {
                onEdit?.call();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final List<MessageAttachment> attachments;
  final bool isUser;
  final bool isDark;

  const _AttachmentRow({
    required this.attachments,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: attachments.map((attachment) {
        if (attachment.mimeType.startsWith('image/')) {
          return _ImageAttachment(attachment: attachment, isUser: isUser, isDark: isDark);
        } else if (attachment.mimeType.startsWith('audio/')) {
          return _AudioAttachment(attachment: attachment, isUser: isUser);
        } else {
          return _FileAttachment(attachment: attachment, isUser: isUser, isDark: isDark);
        }
      }).toList(),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  final MessageAttachment attachment;
  final bool isUser;
  final bool isDark;

  const _ImageAttachment({
    required this.attachment,
    required this.isUser,
    required this.isDark,
  });

  void _showFullscreenImage(BuildContext context) {
    Navigator.of(context).push(
      AppPageTransitions.fadeSlide(
        builder: (context) => FullscreenImageViewer(
          imagePath: attachment.path,
          imageUrl: attachment.url,
          isDark: isDark,
        ),
      ),
    );
  }

  void _showImageContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(Iconsax.fullscreen, color: isDark ? AppColors.textDark : AppColors.textLight),
                title: Text('Vollbild', style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullscreenImage(context);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.link, color: isDark ? AppColors.textDark : AppColors.textLight),
                title: Text('Pfad kopieren', style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: attachment.url ?? attachment.path));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pfad kopiert'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRemote = attachment.url != null;
    final String heroTag = 'image_\${attachment.path}_\${attachment.url ?? ''}';

    return GestureDetector(
      onTap: () => _showFullscreenImage(context),
      onLongPress: () => _showImageContextMenu(context),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            child: isRemote
                ? _ImageWithPlaceholder(imageUrl: attachment.url!, isUser: isUser)
                : _LocalImageWithPlaceholder(imagePath: attachment.path, isUser: isUser),
          ),
        ),
      ),
    );
  }
}

/// Image widget with blur placeholder and crossfade transition
class _ImageWithPlaceholder extends StatefulWidget {
  final String imageUrl;
  final bool isUser;

  const _ImageWithPlaceholder({
    required this.imageUrl,
    required this.isUser,
  });

  @override
  State<_ImageWithPlaceholder> createState() => _ImageWithPlaceholderState();
}

class _ImageWithPlaceholderState extends State<_ImageWithPlaceholder> {
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Blur placeholder (shown while loading or on error)
        if (!_isLoaded)
          const BlurPlaceholder(
            width: 100,
            height: 100,
            borderRadius: AppRadius.medium,
            showShimmer: true,
          ),
        // Actual image with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Image.network(
            widget.imageUrl,
            key: ValueKey(_isLoaded ? widget.imageUrl : 'placeholder'),
            fit: BoxFit.cover,
            width: 200,
            height: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Image loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _isLoaded = true);
                  }
                });
                return child;
              }
              // Still loading - show placeholder (AnimatedSwitcher will handle crossfade)
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              // Error state - keep placeholder visible
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

/// Local image with blur placeholder and crossfade transition
class _LocalImageWithPlaceholder extends StatefulWidget {
  final String imagePath;
  final bool isUser;

  const _LocalImageWithPlaceholder({
    required this.imagePath,
    required this.isUser,
  });

  @override
  State<_LocalImageWithPlaceholder> createState() => _LocalImageWithPlaceholderState();
}

class _LocalImageWithPlaceholderState extends State<_LocalImageWithPlaceholder> {
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Blur placeholder (shown while loading or on error)
        if (!_isLoaded)
          const BlurPlaceholder(
            width: 100,
            height: 100,
            borderRadius: AppRadius.medium,
            showShimmer: true,
          ),
        // Actual image with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Image.file(
            File(widget.imagePath),
            key: ValueKey(_isLoaded ? widget.imagePath : 'placeholder'),
            fit: BoxFit.cover,
            width: 200,
            height: 200,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                // Image loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _isLoaded = true);
                  }
                });
                return child;
              }
              // Still loading - show nothing (placeholder visible)
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              // Error state - keep placeholder visible
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _AudioAttachment extends StatefulWidget {
  final MessageAttachment attachment;
  final bool isUser;

  const _AudioAttachment({required this.attachment, required this.isUser});

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  late VoiceMessageService _voiceService;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceMessageService();
    _voiceService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _voiceService.isPlaying;
      _position = _voiceService.playbackPosition;
      _duration = _voiceService.playbackDuration;
    });
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onServiceUpdate);
    _voiceService.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.isUser ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _voiceService.pausePlayback();
              } else {
                _voiceService.playAudio(widget.attachment.path);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isUser ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Iconsax.pause : Iconsax.play,
                size: 20,
                color: widget.isUser ? AppColors.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voice Message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isUser 
                        ? Colors.white 
                        : (isDark ? AppColors.textDark : AppColors.textLight),
                  ),
                ),
                if (_duration.inSeconds > 0)
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isUser 
                          ? Colors.white70 
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  final MessageAttachment attachment;
  final bool isUser;
  final bool isDark;

  const _FileAttachment({required this.attachment, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.attach_2,
            size: 20,
            color: isUser ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              attachment.fileName,
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders text with blinking cursor when streaming
class _InteractiveText extends StatefulWidget {
  final String content;
  final bool isUser;
  final bool isDark;
  final bool isStreaming;

  const _InteractiveText({
    required this.content,
    required this.isUser,
    required this.isDark,
    required this.isStreaming,
  });

  @override
  State<_InteractiveText> createState() => _InteractiveTextState();
}

class _InteractiveTextState extends State<_InteractiveText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isUser
        ? Colors.white
        : (widget.isDark ? AppColors.textDark : AppColors.textLight);

    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: widget.content,
            style: TextStyle(
              color: textColor,
              height: 1.4,
            ),
          ),
          if (widget.isStreaming)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AnimatedBuilder(
                animation: _cursorController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cursorController.value,
                    child: Container(
                      width: 2,
                      height: 16,
                      margin: const EdgeInsets.only(left: 2, right: 2),
                      color: textColor,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
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

    // Detect language for syntax highlighting
    String language = 'plaintext';
    if (isJson) {
      language = 'json';
    } else if (content.contains('function') || content.contains('const ') || content.contains('let ')) {
      language = 'javascript';
    } else if (content.contains('def ') || content.contains('import ') && content.contains(':')) {
      language = 'python';
    } else if (content.contains('class ') && content.contains('extends')) {
      language = 'dart';
    }

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language badge
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    top: AppSpacing.xs,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Code content
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: HighlightView(
                    displayContent,
                    language: language,
                    theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            // Copy button
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Iconsax.tick_square, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            const Text('Copied to clipboard'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    HapticService.lightImpact();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Iconsax.copy,
                      size: 14,
                      color: (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        return Iconsax.play_circle_outline;
      case 'success':
        return Iconsax.tick_square_circle;
      case 'failed':
        return Iconsax.warning_2;
      default:
        return Iconsax.info_circle;
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
                          Iconsax.heart,
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
                            Iconsax.arrow_down_1,
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
  final bool pushToTalkMode;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onImageSelected,
    this.enabled = true,
    this.showVoiceInput = true,
    this.pushToTalkMode = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with ChangeNotifier {
  final _controller = TextEditingController();
  bool _isRecording = false;
  bool _isRecordingVoiceMessage = false;
  bool _isPttHolding = false;
  VoiceInputService? _voiceService;
  VoiceMessageService? _voiceMessageService;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceInputService();
    _voiceService!.addListener(_onVoiceStateChange);
    _voiceMessageService = VoiceMessageService();
  }

  void _onVoiceStateChange() {
    if (!mounted) return;
    
    final isListening = _voiceService?.isListening ?? false;
    final text = _voiceService?.transcribedText ?? '';
    
    setState(() {
      _isRecording = isListening;
      // Update text field with transcribed text
      if (text.isNotEmpty && isListening) {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      }
    });

    // If listening stopped and we have text, auto-send
    if (!isListening && text.isNotEmpty) {
      final textToSend = text;
      _controller.clear();
      _voiceService?.clearText();
      widget.onSend(textToSend);
    }
  }

  @override
  void dispose() {
    _voiceService?.removeListener(_onVoiceStateChange);
    _voiceService?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPttPress() {
    if (!widget.enabled) return;
    _voiceService?.startListening();
    setState(() => _isPttHolding = true);
    HapticService.lightImpact();
  }

  void _onPttRelease() {
    _voiceService?.stopListening();
    setState(() => _isPttHolding = false);
  }

  void _toggleRecording() {
    if (_isRecording) {
      _voiceService?.stopListening();
    } else {
      _voiceService?.startListening();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSend(text);
      _controller.clear();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        widget.onImageSelected?.call(image.path);
      }
    } catch (e) {
      AppLogger.error('Camera pick failed: $e', tag: 'CHAT_WIDGETS');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        widget.onImageSelected?.call(image.path);
      }
    } catch (e) {
      AppLogger.error('Gallery pick failed: $e', tag: 'CHAT_WIDGETS');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.bgDarkSecondary
              : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.microphone, color: AppColors.error),
                title: const Text('Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  _startVoiceMessageRecording();
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.camera, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: AppColors.secondary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceMessageRecording() async {
    if (_isRecordingVoiceMessage) {
      // Stop recording and send
      final path = await _voiceMessageService?.stopRecording();
      if (path != null && mounted) {
        final fileName = path.split('/').last;
        final attachment = MessageAttachment(
          path: path,
          fileName: fileName,
          mimeType: 'audio/m4a',
        );
        widget.onSend('[Voice Message]');
      }
      setState(() => _isRecordingVoiceMessage = false);
    } else {
      // Start recording
      final success = await _voiceMessageService?.startRecording();
      if (success == true) {
        setState(() => _isRecordingVoiceMessage = true);
      }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice Message Recording indicator
            if (_isRecordingVoiceMessage)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Voice Message recording...',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _formatDuration(_voiceMessageService?.recordingDuration ?? Duration.zero),
                      style: TextStyle(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            // Speech-to-Text Recording indicator
            if (_isRecording && !_isRecordingVoiceMessage)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Recording...',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        _voiceService?.transcribedText ?? '',
                        style: TextStyle(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Main input row
            Row(
              children: [
                if (widget.showVoiceInput)
                  widget.pushToTalkMode
                      ? _PushToTalkButton(
                          isHolding: _isPttHolding,
                          enabled: widget.enabled,
                          onPress: _onPttPress,
                          onRelease: _onPttRelease,
                        )
                      : _AnimatedVoiceButton(
                          isRecording: _isRecording,
                          enabled: widget.enabled,
                          onPressed: _toggleRecording,
                        ),
                IconButton(
                  icon: const Icon(Iconsax.attach_2, color: AppColors.primary),
                  onPressed: widget.enabled ? _showAttachmentOptions : null,
                  tooltip: 'Add attachment',
                ),
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter, controlPressed: true): _send,
                    },
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled && !_isRecording,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: _isRecording 
                            ? 'Listening...' 
                            : 'Nachricht eingeben... (Ctrl+Enter zum Senden)',
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
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: widget.enabled ? AppColors.primary : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Iconsax.send, color: Colors.white, size: 20),
                    onPressed: widget.enabled ? _send : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _AnimatedVoiceButton extends StatefulWidget {
  final bool isRecording;
  final bool enabled;
  final VoidCallback onPressed;

  const _AnimatedVoiceButton({
    required this.isRecording,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_AnimatedVoiceButton> createState() => _AnimatedVoiceButtonState();
}

class _AnimatedVoiceButtonState extends State<_AnimatedVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = widget.isRecording ? _scaleAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: IconButton(
            icon: Icon(
              widget.isRecording ? Iconsax.stop : Iconsax.microphone,
              color: widget.isRecording ? AppColors.error : AppColors.primary,
            ),
            onPressed: widget.enabled ? widget.onPressed : null,
            tooltip: widget.isRecording ? 'Stop recording' : 'Voice input',
          ),
        );
      },
    );
  }
}


/// Push-to-Talk button - hold to record, release to send
class _PushToTalkButton extends StatefulWidget {
  final bool isHolding;
  final bool enabled;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  const _PushToTalkButton({
    required this.isHolding,
    required this.enabled,
    required this.onPress,
    required this.onRelease,
  });

  @override
  State<_PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<_PushToTalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_PushToTalkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHolding && !oldWidget.isHolding) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHolding && oldWidget.isHolding) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isHolding ? _scaleAnimation.value : 1.0;
        final glow = widget.isHolding ? _glowAnimation.value : 0.0;
        
        return GestureDetector(
          onTapDown: widget.enabled ? (_) => widget.onPress() : null,
          onTapUp: widget.enabled ? (_) => widget.onRelease() : null,
          onTapCancel: widget.enabled ? widget.onRelease : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isHolding 
                  ? AppColors.error.withOpacity(0.2) 
                  : AppColors.bgDarkTertiary,
              border: Border.all(
                color: widget.isHolding 
                    ? AppColors.error 
                    : (widget.enabled ? AppColors.primary : Colors.grey),
                width: 2,
              ),
              boxShadow: widget.isHolding
                  ? [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3 * glow),
                        blurRadius: 12 * glow,
                        spreadRadius: 2 * glow,
                      ),
                    ]
                  : null,
            ),
            child: Transform.scale(
              scale: scale,
              child: Icon(
                widget.isHolding ? Iconsax.microphone : Iconsax.microphone_none,
                color: widget.isHolding ? AppColors.error : AppColors.primary,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

