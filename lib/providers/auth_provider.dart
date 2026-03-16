import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/services/websocket_service.dart';
import '../../models/message.dart';

class AuthProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String? _gatewayUrl;
  String? _token;
  bool _isLoading = false;
  bool _useBiometrics = false;
  String? _selectedAgent;

  WebSocketService get ws => _ws;
  String? get gatewayUrl => _gatewayUrl;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _gatewayUrl != null;
  bool get useBiometrics => _useBiometrics;
  String? get selectedAgent => _selectedAgent;
  bool get isConnected => _ws.isConnected;

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
      
      // Auto-login if credentials exist
      if (_gatewayUrl != null && _token != null) {
        debugPrint('Auto-login with saved credentials...');
        await _ws.connect(_gatewayUrl!, _token!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
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
      debugPrint('Login error: $e');
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

  Future<void> setGatewayUrl(String url) async {
    _gatewayUrl = url;
    await _secureStorage.write(key: 'gateway_url', value: url);
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _secureStorage.write(key: 'gateway_token', value: token);
    notifyListeners();
  }

  Future<void> setSelectedAgent(String? agent) async {
    _selectedAgent = agent;
    final prefs = await SharedPreferences.getInstance();
    if (agent != null) {
      await prefs.setString('selected_agent', agent);
    } else {
      await prefs.remove('selected_agent');
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_gatewayUrl != null && _token != null) {
      await _ws.connect(_gatewayUrl!, _token!);
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _ws.disconnect();
    notifyListeners();
  }

  // Reconnection
  Future<void> reconnect() async {
    if (_gatewayUrl != null && _token != null) {
      await _ws.connect(_gatewayUrl!, _token!);
      notifyListeners();
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  Color _accentColor = AppColors.primary;

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? true;
    final accentColorValue = prefs.getInt('accent_color');
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveTheme();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setInt('accent_color', _accentColor.value);
  }
}
