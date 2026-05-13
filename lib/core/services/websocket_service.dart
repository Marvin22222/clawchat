import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Batch duration for UI updates (ms) - prevents excessive rebuilds
const int _kMessageBatchDurationMs = 16; // ~60fps max

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _gatewayUrl;
  String? _token;
  List<String> _availableAgents = [];
  String? _systemPrompt; // Active system prompt override
  
  // Auto-reconnect settings
  bool _autoReconnect = true;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  
  // Callbacks
  Function(String)? onMessage;
  Function(String)? onThinking;
  Function(Map<String, dynamic>)? onToolCall;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function()? onStreamingStart;  // New: called when assistant starts streaming
  Function()? onStreamingEnd;    // New: called when streaming is complete
  Function(String messageId)? onMessageRead;  // Called when a message read receipt is received

  // Message batching for UI performance
  Timer? _messageBatchTimer;
  String _pendingMessageContent = '';
  String? _pendingStreamingId;

  ConnectionStatus get status => _status;
  List<String> get availableAgents => _availableAgents;
  bool get isConnected => _status == ConnectionStatus.connected;

  Future<bool> connect(String gatewayUrl, String token) async {
    _gatewayUrl = gatewayUrl;
    _token = token;
    _status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      // Build WebSocket URL
      String wsUrl;
      if (gatewayUrl.startsWith('ws://') || gatewayUrl.startsWith('wss://')) {
        wsUrl = gatewayUrl;
      } else if (gatewayUrl.startsWith('http://')) {
        wsUrl = gatewayUrl.replaceFirst('http://', 'ws://');
      } else if (gatewayUrl.startsWith('https://')) {
        wsUrl = gatewayUrl.replaceFirst('https://', 'wss://');
      } else {
        wsUrl = 'wss://$gatewayUrl';
      }
      
      // Add token as query parameter
      if (!wsUrl.contains('?')) {
        wsUrl += '?token=$token';
      } else {
        wsUrl += '&token=$token';
      }
      
      wsUrl += '&type=app'; // Mark as app connection

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          _status = ConnectionStatus.error;
          onError?.call(error.toString());
          notifyListeners();
        },
        onDone: () {
          _status = ConnectionStatus.disconnected;
          onDisconnected?.call();
          notifyListeners();
          
          // Auto-reconnect
          if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnect();
          }
        },
      );

      // Wait for connection
      await Future.delayed(const Duration(seconds: 2));
      
      // Send auth
      _send({'type': 'auth', 'token': token});
      
      _status = ConnectionStatus.connected;
      onConnected?.call();
      notifyListeners();
      return true;
    } catch (e) {
      _status = ConnectionStatus.error;
      onError?.call(e.toString());
      notifyListeners();
      return false;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String);
      final type = message['type'];

      switch (type) {
        case 'auth_success':
          _availableAgents = List<String>.from(message['agents'] ?? []);
          notifyListeners();
          break;
        case 'message_stream_start':
          onStreamingStart?.call();
          break;
        case 'message_chunk': {
          // Batch rapid messages together to reduce UI rebuilds
          final content = message['content'] ?? '';
          final streamingId = message['streamingId'];
          if (streamingId != null) {
            _pendingStreamingId = streamingId;
          }
          _pendingMessageContent += content;
          _scheduleMessageBatch();
          break;
        }
        case 'message_stream_end':
          onStreamingEnd?.call();
          break;
        case 'thinking':
          onThinking?.call(message['content'] ?? '');
          break;
        case 'tool_call_start':
        case 'tool_call_progress':
        case 'tool_call_end':
          onToolCall?.call(message);
          break;
        case 'message_read':
          onMessageRead?.call(message['messageId'] ?? '');
          break;
        case 'error':
          onError?.call(message['message'] ?? 'Unknown error');
          break;
      }
    } catch (e) {
      // Handle non-JSON messages
      onMessage?.call(data.toString());
    }
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> sendMessage(String content, {String agent = 'main', List<Map<String, dynamic>>? attachments, String? replyToId, String? replyToContent}) async {
    _send({
      'type': 'message',
      'content': content,
      'agent': agent,
      if (attachments != null) 'attachments': attachments,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToContent != null) 'replyToContent': replyToContent,
    });
  }

  void sendAttachment(String path, String fileName, String mimeType, {String? text}) {
    _send({
      'type': 'attachment',
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
      if (text != null) 'text': text,
    });
  }

  void switchAgent(String agent) {
    _send({
      'type': 'agent_switch',
      'agent': agent,
    });
  }

  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    _send({
      'type': 'system_prompt_set',
      'prompt': prompt,
    });
  }

  void clearSystemPrompt() {
    _systemPrompt = null;
    _send({
      'type': 'system_prompt_clear',
    });
  }

  String? get systemPrompt => _systemPrompt;

  void disconnect() {
    _autoReconnect = false;
    _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff
    
    Future.delayed(delay, () {
      if (_autoReconnect && _status != ConnectionStatus.connected) {
        connect(_gatewayUrl!, _token!);
      }
    });
  }

  Future<bool> reconnect() async {
    _reconnectAttempts = 0;
    _autoReconnect = true;
    return await connect(_gatewayUrl!, _token!);
  }

  void _scheduleMessageBatch() {
    _messageBatchTimer?.cancel();
    _messageBatchTimer = Timer(
      const Duration(milliseconds: _kMessageBatchDurationMs),
      _flushMessageBatch,
    );
  }

  void _flushMessageBatch() {
    if (_pendingMessageContent.isNotEmpty) {
      onMessage?.call(_pendingMessageContent);
      _pendingMessageContent = '';
      _pendingStreamingId = null;
    }
  }

  @override
  void dispose() {
    _messageBatchTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    super.dispose();
  }
}