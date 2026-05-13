import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/message.dart';

/// Service for sharing chat content externally
class ShareService {
  /// Share plain text to other apps
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  /// Share an image file to other apps
  static Future<void> shareImage(String path) async {
    final file = XFile(path);
    await Share.shareXFiles([file]);
  }

  /// Share multiple files to other apps
  static Future<void> shareFiles(List<String> paths) async {
    final files = paths.map((p) => XFile(p)).toList();
    await Share.shareXFiles(files);
  }

  /// Export chat as formatted text
  static Future<void> shareChatAsText(
    List<ChatMessage> messages, {
    String? chatTitle,
  }) async {
    final buffer = StringBuffer();
    
    if (chatTitle != null) {
      buffer.writeln('═══ $chatTitle ═══');
      buffer.writeln();
    }
    
    for (final message in messages) {
      final sender = message.type == MessageType.user 
          ? 'Du' 
          : (message.agentName ?? 'Assistant');
      
      final time = _formatTimestamp(message.timestamp);
      final content = message.content;
      
      buffer.writeln('[$time] $sender:');
      buffer.writeln(content);
      
      // Include reply context if present
      if (message.replyToContent != null && message.replyToContent!.isNotEmpty) {
        buffer.writeln('  ↳ Antwort auf: ${message.replyToContent}');
      }
      
      // Include reactions if present
      if (message.reactions != null && message.reactions!.isNotEmpty) {
        final reactionStr = message.reactions!.entries
            .map((e) => '${e.key} (${e.value})')
            .join(' ');
        buffer.writeln('  ↳ Reaktionen: $reactionStr');
      }
      
      if (message.isEdited) {
        buffer.writeln('  (bearbeitet)');
      }
      
      buffer.writeln();
    }
    
    await Share.share(buffer.toString().trim());
  }

  /// Export chat as JSON (for backup/import)
  static Future<void> shareChatAsJson(
    List<ChatMessage> messages, {
    String? chatTitle,
  }) async {
    final jsonData = <String, dynamic>{
      'title': chatTitle ?? 'Chat Export',
      'exportedAt': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
      'messages': messages.map((m) => {
        'id': m.id,
        'content': m.content,
        'type': m.type.name,
        'timestamp': m.timestamp.toIso8601String(),
        'agentName': m.agentName,
        'status': m.status?.name,
        'isEdited': m.isEdited,
        'replyToId': m.replyToId,
        'replyToContent': m.replyToContent,
        'reactions': m.reactions,
        'attachments': m.attachments?.map((a) => {
          'path': a.path,
          'fileName': a.fileName,
          'mimeType': a.mimeType,
        }).toList(),
      }).toList(),
    };

    // Write to temp file and share
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/chat_export_$timestamp.json');
    await file.writeAsString(jsonData.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Chat Export');
  }

  /// Share a single message with context
  static Future<void> shareMessage(ChatMessage message) async {
    final sender = message.type == MessageType.user 
        ? 'Du' 
        : (message.agentName ?? 'Assistant');
    
    final time = _formatTimestamp(message.timestamp);
    
    final buffer = StringBuffer();
    buffer.writeln('Nachricht von $sender ($time):');
    buffer.writeln();
    buffer.writeln(message.content);
    
    if (message.replyToContent != null && message.replyToContent!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Antwort auf: ${message.replyToContent}');
    }
    
    await Share.share(buffer.toString().trim());
  }

  /// Share text to a specific agent (OpenClaw integration)
  /// Returns the text that should be sent to the agent
  static Future<String> prepareTextForAgent(String text) async {
    return text;
  }

  /// Format timestamp for export
  static String _formatTimestamp(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
           '${dt.month.toString().padLeft(2, '0')}.'
           '${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Share options enum for bottom sheet
enum ShareOption {
  shareMessage,
  shareChat,
  exportJson,
  copyLink,
}

/// Share option data class
class ShareOptionData {
  final ShareOption option;
  final String title;
  final String subtitle;
  final IconData icon;

  const ShareOptionData({
    required this.option,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Bottom sheet with share options
class ShareOptionsSheet extends StatelessWidget {
  final List<ShareOptionData> options;
  final VoidCallback? onDismiss;

  const ShareOptionsSheet({
    super.key,
    required this.options,
    this.onDismiss,
  });

  static Future<ShareOption?> show(
    BuildContext context, {
    required List<ShareOptionData> options,
  }) async {
    return showModalBottomSheet<ShareOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsSheet(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Iconsax.share,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Teilen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options
            ...options.map((option) => ListTile(
              leading: Icon(option.icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
              title: Text(
                option.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                option.subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              onTap: () => Navigator.pop(context, option.option),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
