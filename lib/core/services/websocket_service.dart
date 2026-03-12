import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _gatewayUrl;
  String? _token;
  List<String> _availableAgents = [];
  
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
        case 'message_chunk':
          onMessage?.call(message['content'] ?? '');
          break;
        case 'thinking':
          onThinking?.call(message['content'] ?? '');
          break;
        case 'tool_call_start':
        case 'tool_call_progress':
        case 'tool_call_end':
          onToolCall?.call(message);
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

  void sendMessage(String content, {String agent = 'main'}) {
    _send({
      'type': 'message',
      'content': content,
      'agent': agent,
    });
  }

  void switchAgent(String agent) {
    _send({
      'type': 'agent_switch',
      'agent': agent,
    });
  }

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

  @override
  void dispose() {
    _channel?.sink.close();
    _channel = null;
    super.dispose();
  }
}
