import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../utils/logger.dart';

/// Firebase Cloud Messaging Notification Service
/// Handles push notifications for both iOS and Android
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isInitialized = false;
  String? _fcmToken;

  // Getters
  bool get isEnabled => _isEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialized', tag: 'NOTIF');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Set up FCM message handlers
      _setupFirebaseMessagingHandlers();

      // Get and store FCM token
      await _getFcmToken();

      _isInitialized = true;
      AppLogger.info('NotificationService initialized', tag: 'NOTIF');
      notifyListeners();
    } catch (e) {
      AppLogger.error('NotificationService initialization failed: $e', tag: 'NOTIF');
      // Don't crash - notifications are optional
      _isInitialized = false;
    }
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    AppLogger.info('Local notifications initialized', tag: 'NOTIF');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.debug('iOS Notification Permission: ${settings.authorizationStatus.name}', tag: 'NOTIF');

    } else if (Platform.isAndroid) {
      // Android permissions are handled automatically
      final android = _firebaseMessaging;
      AppLogger.debug('Android notification permissions configured', tag: 'NOTIF');
    }
  }

  /// Set up Firebase Messaging handlers for foreground and background messages
  void _setupFirebaseMessagingHandlers() {
    // Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification (cold start)
    _checkInitialMessage();
  }

  /// Handle incoming messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.debug('Foreground message received: ${message.notification?.title}', tag: 'NOTIF');

    await _showLocalNotification(
      title: message.notification?.title ?? 'ClawChat',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle when user taps on a notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.debug('App opened from notification: ${message.notification?.title}', tag: 'NOTIF');
    _navigateToNotification(message.data);
  }

  /// Check for initial message (cold start from notification)
  Future<void> _checkInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      AppLogger.debug('Cold start from notification: ${message.notification?.title}', tag: 'NOTIF');
      _navigateToNotification(message.data);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      'clawchat_messages',
      'Messages',
      channelDescription: 'Chat message notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: _vibrationEnabled,
      playSound: _soundEnabled,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap - navigate to relevant screen
  void _onNotificationResponse(NotificationResponse response) {
    AppLogger.debug('Notification tapped: ${response.payload}', tag: 'NOTIF');
    // Parse payload and navigate to appropriate screen
    // This would integrate with the app's navigation
  }

  /// Navigate based on notification data
  void _navigateToNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'message':
        // Navigate to chat
        AppLogger.debug('Navigate to chat screen', tag: 'NOTIF');
        break;
      case 'task':
        // Navigate to tasks
        AppLogger.debug('Navigate to tasks screen', tag: 'NOTIF');
        break;
      default:
        // Navigate to home
        AppLogger.debug('Navigate to home screen', tag: 'NOTIF');
    }
  }

  /// Get FCM token
  Future<void> _getFcmToken() async {
    try {
      // Check if token exists in storage
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token');

      if (storedToken != null) {
        _fcmToken = storedToken;
        AppLogger.debug('Using stored FCM token', tag: 'FCM');
      } else {
        // Get fresh token
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          await prefs.setString('fcm_token', _fcmToken!);
          AppLogger.debug('New FCM token received', tag: 'FCM');
          
          // Send token to gateway
          await _sendTokenToGateway(_fcmToken!);
        }
      }

      AppLogger.debug('FCM Token: ${_fcmToken?.substring(0, 20)}...', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to get FCM token: $e', tag: 'FCM');
    }
  }

  /// Send FCM token to Gateway for push notification routing
  Future<void> _sendTokenToGateway(String token) async {
    try {
      // Get stored gateway URL
      final prefs = await SharedPreferences.getInstance();
      final gatewayUrl = prefs.getString(AppConfig.keyGatewayUrl) ?? 
                         AppConfig.defaultGatewayUrl;

      // Build the URL
      final uri = Uri.parse('http://$gatewayUrl/api/devices/register');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app': 'clawchat',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppLogger.info('FCM token sent to gateway successfully', tag: 'FCM');
      } else {
        AppLogger.warning('Gateway rejected token: ${response.statusCode}', tag: 'FCM');
      }
    } catch (e) {
      AppLogger.warning('Failed to send token to gateway: $e', tag: 'FCM');
      // Don't crash - token registration is optional
    }
  }

  /// Refresh FCM token (call when token changes)
  Future<void> refreshToken() async {
    await _getFcmToken();
  }

  /// Send token to gateway on demand
  Future<void> registerDeviceWithGateway(String gatewayUrl, String? authToken) async {
    if (_fcmToken == null) {
      AppLogger.warning('No FCM token available', tag: 'FCM');
      return;
    }

    try {
      final uri = Uri.parse('http://$gatewayUrl/api/devices/register');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': _fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app': 'clawchat',
        }),
      ).timeout(const Duration(seconds: 10));

      AppLogger.debug('Device registration response: ${response.statusCode}', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to register device: $e', tag: 'FCM');
    }
  }

  // ========== Settings ==========

  void setEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _isEnabled);
    await prefs.setBool('notifications_sound', _soundEnabled);
    await prefs.setBool('notifications_vibration', _vibrationEnabled);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('notifications_sound') ?? true;
    _vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
  }

  // ========== Public Notification Methods ==========

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isEnabled) return;

    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Show a chat message notification
  Future<void> showMessageNotification({
    required String sender,
    required String message,
  }) async {
    await showNotification(
      title: sender,
      body: message.length > 100
          ? '${message.substring(0, 100)}...'
          : message,
      payload: jsonEncode({'type': 'message', 'sender': sender}),
    );
  }

  /// Show a task notification
  Future<void> showTaskNotification({
    required String taskName,
    required String status,
  }) async {
    await showNotification(
      title: 'Task $status',
      body: taskName,
      payload: jsonEncode({'type': 'task', 'status': status}),
    );
  }

  /// Show a custom notification with data
  Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      title: title,
      body: body,
      payload: data != null ? jsonEncode(data) : null,
    );
  }
}
