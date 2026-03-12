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

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? true;
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

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
  }
}
