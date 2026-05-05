import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/message.dart';

/// Service for persisting chat messages locally
class ChatPersistenceService {
  static const String _messagesKey = 'chat_messages';
  static const int _maxMessages = 100; // Keep last 100 messages

  /// Save messages to local storage
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Take only the last _maxMessages
      final messagesToSave = messages.length > _maxMessages
          ? messages.sublist(messages.length - _maxMessages)
          : messages;
      
      final jsonList = messagesToSave.map((m) => _messageToJson(m)).toList();
      await prefs.setString(_messagesKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail - chat persistence is not critical
      print('Failed to save messages: $e');
    }
  }

  /// Load messages from local storage
  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messagesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('Failed to load messages: $e');
      return [];
    }
  }

  /// Clear all saved messages
  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
    } catch (e) {
      print('Failed to clear messages: $e');
    }
  }

  /// Export messages as JSON string
  static String exportAsJson(List<ChatMessage> messages) {
    final jsonList = messages.map((m) => _messageToJson(m)).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }


  /// Export messages as plain text
  static String exportAsText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('=== ClawChat Export ===');
    buffer.writeln('Exportiert am: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Nachrichten: ${messages.length}');
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('');

    for (final msg in messages) {
      final typeLabel = msg.type == MessageType.user ? 'Du' : 'Assistant';
      final agentInfo = msg.agentName != null ? ' [${msg.agentName}]' : '';
      buffer.writeln('[$typeLabel$agentInfo - ${_formatTimestamp(msg.timestamp)}]');
      buffer.writeln(msg.content);
      buffer.writeln('');
    }

    return buffer.toString();
  }


  static String _formatTimestamp(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute';
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'type': message.type.index,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'status': message.status.index,
      'agentName': message.agentName,
      'attachments': message.attachments?.map((a) => {
        'path': a.path,
        'fileName': a.fileName,
        'mimeType': a.mimeType,
        'size': a.size,
      }).toList(),
      'reactions': message.reactions,
    };
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values[json['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values[json['status']],
      agentName: json['agentName'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => MessageAttachment(
              path: a['path'],
              fileName: a['fileName'],
              mimeType: a['mimeType'] ?? 'image/jpeg',
              size: a['size'],
            )).toList()
          : null,
      reactions: json['reactions'] != null
          ? Map<String, int>.from(json['reactions'])
          : null,
    );
  }
}
