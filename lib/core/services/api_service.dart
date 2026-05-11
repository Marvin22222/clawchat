import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/message.dart';
import '../utils/logger.dart';

/// API Service for REST calls to the OpenClaw gateway
/// Used for message editing, fetching conversation history, etc.
class ApiService {
  String? _gatewayUrl;
  String? _token;

  void configure(String gatewayUrl, String token) {
    _gatewayUrl = gatewayUrl;
    _token = token;
  }

  String get _baseUrl {
    if (_gatewayUrl == null) return '';
    // Ensure we have http:// or https:// prefix
    if (!_gatewayUrl!.startsWith('http://') && !_gatewayUrl!.startsWith('https://')) {
      return 'https://$_gatewayUrl';
    }
    return _gatewayUrl!;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Update/Edit a message via PUT /api/messages/{messageId}
  /// Returns the updated message on success, null on failure
  Future<ChatMessage?> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    if (_gatewayUrl == null || _token == null) {
      AppLogger.warning('ApiService: Not configured, cannot edit message', tag: 'API');
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/messages/$messageId');
      final response = await http.put(
        uri,
        headers: _headers,
        body: json.encode({
          'content': newContent,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('Message edited successfully: $messageId', tag: 'API');
        return ChatMessage.fromJson(data);
      } else {
        AppLogger.error('Failed to edit message: ${response.statusCode} - ${response.body}', tag: 'API');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error editing message: $e', tag: 'API');
      return null;
    }
  }

  /// Fetch a single message by ID via GET /api/messages/{messageId}
  Future<ChatMessage?> getMessage(String messageId) async {
    if (_gatewayUrl == null || _token == null) {
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/messages/$messageId');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data);
      }
    } catch (e) {
      AppLogger.error('Error fetching message: $e', tag: 'API');
    }
    return null;
  }

  /// Fetch conversation history via GET /api/conversations/{conversationId}/messages
  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    if (_gatewayUrl == null || _token == null) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/conversations/$conversationId/messages');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((m) => ChatMessage.fromJson(m)).toList();
      }
    } catch (e) {
      AppLogger.error('Error fetching conversation messages: $e', tag: 'API');
    }
    return [];
  }
}

// Extension to parse ChatMessage from JSON (for API responses)
extension ChatMessageFromJson on ChatMessage {
  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: _parseMessageType(json['type'] as String?),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: _parseMessageStatus(json['status'] as String?),
      agentName: json['agentName'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'user':
        return MessageType.user;
      case 'assistant':
        return MessageType.assistant;
      case 'system':
        return MessageType.system;
      case 'thinking':
        return MessageType.thinking;
      case 'toolCall':
        return MessageType.toolCall;
      default:
        return MessageType.assistant;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'error':
        return MessageStatus.error;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}