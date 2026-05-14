import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../core/services/theme_service.dart';
import '../core/services/websocket_service.dart';
import '../core/services/api_service.dart';
import '../core/utils/logger.dart';
import '../models/message.dart';

class AuthProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();
  final ApiService _api = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String? _gatewayUrl;
  String? _token;
  bool _isLoading = false;
  bool _useBiometrics = false;
  bool? _useAutoLock;
  int? _autoLockMinutes;
  String? _selectedAgent;
  DateTime? _backgroundedAt;

  WebSocketService get ws => _ws;
  ApiService get api => _api;
  String? get gatewayUrl => _gatewayUrl;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _gatewayUrl != null;
  bool get useBiometrics => _useBiometrics;
  bool? get useAutoLock => _useAutoLock;
  int? get autoLockMinutes => _autoLockMinutes;
  String? get selectedAgent => _selectedAgent;
  bool get isConnected => _ws.isConnected;

  AuthProvider() {
    _loadSavedCredentialsAsync();
  }

  Future<void> _loadSavedCredentialsAsync() async {
    _isLoading = true;
    notifyListeners();

    try {
      _gatewayUrl = await _secureStorage.read(key: 'gateway_url');
      _token = await _secureStorage.read(key: 'gateway_token');
      _useBiometrics = await _getBiometricPreference();
      _useAutoLock = await _getAutoLockPreference();
      _autoLockMinutes = await _getAutoLockMinutesPreference();
      
      // Configure API service
      if (_gatewayUrl != null && _token != null) {
        _api.configure(_gatewayUrl!, _token!);
      }
      
      // Deferred: Don't block UI with auto-connect on startup
      // Connect will happen lazily when user interacts or AppWrapper checks connection
    } catch (e) {
      AppLogger.warning('Error loading credentials: $e', tag: 'AUTH');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _getBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_biometrics') ?? false;
  }

  Future<bool> _getAutoLockPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_auto_lock') ?? false;
  }

  Future<int?> _getAutoLockMinutesPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('auto_lock_minutes');
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
        // Configure API service with new credentials
        _api.configure(gatewayUrl, token);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      AppLogger.error('Login error: $e', tag: 'AUTH');
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

  Future<void> setUseAutoLock(bool value) async {
    _useAutoLock = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_auto_lock', value);
    notifyListeners();
  }

  Future<void> setAutoLockMinutes(int? minutes) async {
    _autoLockMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    if (minutes != null) {
      await prefs.setInt('auto_lock_minutes', minutes);
    } else {
      await prefs.remove('auto_lock_minutes');
    }
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
      _api.configure(_gatewayUrl!, _token!);
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _ws.disconnect();
    notifyListeners();
  }

  // Auto-lock feature
  static const Duration _autoLockDuration = Duration(minutes: 5);

  void startAutoLockTimer() {
    _backgroundedAt = DateTime.now();
  }

  void cancelAutoLockTimer() {
    if (_backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed < _autoLockDuration) {
        // Not expired yet, just cancel
        _backgroundedAt = null;
        return;
      }
    }
    _backgroundedAt = null;
  }

  bool shouldAutoLock() {
    if (_backgroundedAt == null) return false;
    final elapsed = DateTime.now().difference(_backgroundedAt!);
    return elapsed >= _autoLockDuration;
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
  bool _useSystemTheme = false;
  Color _accentColor = AppColors.primary;
  AppThemeType _themeType = AppThemeType.dark;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;
  Color get accentColor => _accentColor;
  AppThemeType get themeType => _themeType;

  ThemeMode get themeMode {
    if (_useSystemTheme) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? true;
    _useSystemTheme = prefs.getBool('use_system_theme') ?? false;
    final accentColorValue = prefs.getInt('accent_color');
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    final themeTypeIndex = prefs.getInt('theme_type_index');
    if (themeTypeIndex != null && themeTypeIndex < AppThemeType.values.length) {
      _themeType = AppThemeType.values[themeTypeIndex];
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

  void setUseSystemTheme(bool value) {
    _useSystemTheme = value;
    _saveTheme();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _saveTheme();
    notifyListeners();
  }

  void setThemeType(AppThemeType type) {
    _themeType = type;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('use_system_theme', _useSystemTheme);
    await prefs.setInt('accent_color', _accentColor.value);
    await prefs.setInt('theme_type_index', _themeType.index);
  }
}
