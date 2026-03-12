import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/websocket_service.dart';
import '../../models/message.dart';

class AuthProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String? _gatewayUrl;
  String? _token;
  bool _isLoading = false;
  bool _useBiometrics = false;

  WebSocketService get ws => _ws;
  String? get gatewayUrl => _gatewayUrl;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _gatewayUrl != null;
  bool get useBiometrics => _useBiometrics;

  AuthProvider() {
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    _isLoading = true;
    notifyListeners();

    try {
      _gatewayUrl = await _secureStorage.read(key: 'gateway_url');
      _token = await _secureStorage.read(key: 'gateway_token');
      _useBiometrics = await _getBiometricPreference();
    } catch (e) {
      // Ignore errors during loading
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _getBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_biometrics') ?? false;
  }

  Future<bool> login(String gatewayUrl, String token, {bool saveCredentials = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _ws.connect(gatewayUrl, token);
      
      if (success && saveCredentials) {
        await _secureStorage.write(key: 'gateway_url', value: gatewayUrl);
        await _secureStorage.write(key: 'gateway_token', value: token);
        _gatewayUrl = gatewayUrl;
        _token = token;
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _ws.disconnect();
    await _secureStorage.delete(key: 'gateway_token');
    _token = null;
    notifyListeners();
  }

  Future<void> setUseBiometrics(bool value) async {
    _useBiometrics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', value);
    notifyListeners();
  }
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  String? _currentAgent;
  bool _isTyping = false;
  String _thinkingText = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get currentAgent => _currentAgent;
  bool get isTyping => _isTyping;
  String get thinkingText => _thinkingText;

  void setCurrentAgent(String agent) {
    _currentAgent = agent;
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateLastMessage(String content) {
    if (_messages.isNotEmpty) {
      _messages.last.copyWith(content: content);
      notifyListeners();
    }
  }

  void setTyping(bool typing, {String? thinking}) {
    _isTyping = typing;
    _thinkingText = thinking ?? '';
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}
