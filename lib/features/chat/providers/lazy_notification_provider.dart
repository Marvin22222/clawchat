import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';

/// LazyNotificationProvider - Deferred initialization for NotificationService
/// 
/// NotificationService is heavy (Firebase initialization) so we defer it until
/// the user actually needs notifications. This significantly reduces cold start time.
class LazyNotificationProvider extends ChangeNotifier {
  NotificationService? _service;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  NotificationService get service {
    _ensureInitialized();
    return _service!;
  }
  
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  
  // Forward notification service properties
  bool get isEnabled => _service?.isEnabled ?? true;
  bool get soundEnabled => _service?.soundEnabled ?? true;
  bool get vibrationEnabled => _service?.vibrationEnabled ?? true;
  
  /// Initialize on first access (lazy loading)
  void _ensureInitialized() {
    if (_service != null) return;
    
    _isLoading = true;
    notifyListeners();
    
    _service = NotificationService();
    
    // Initialize if not already done
    if (!_service!.isInitialized) {
      // Fire and forget - don't block UI
      _initAsync();
    } else {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _initAsync() async {
    try {
      await _service!.initialize();
      _isInitialized = _service!.isInitialized;
    } catch (e) {
      // Notifications are optional - don't crash
      debugPrint('LazyNotificationProvider init failed: $e');
      _isInitialized = false;
    }
    _isLoading = false;
    notifyListeners();
  }
  
  // Settings methods
  void setEnabled(bool value) {
    _ensureInitialized();
    _service?.setEnabled(value);
    notifyListeners();
  }
  
  void setSoundEnabled(bool value) {
    _ensureInitialized();
    _service?.setSoundEnabled(value);
    notifyListeners();
  }
  
  void setVibrationEnabled(bool value) {
    _ensureInitialized();
    _service?.setVibrationEnabled(value);
    notifyListeners();
  }
  
  // Notification methods
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _ensureInitialized();
    await _service?.showNotification(title: title, body: body, payload: payload);
  }
  
  Future<void> showMessageNotification({
    required String sender,
    required String message,
  }) async {
    _ensureInitialized();
    await _service?.showMessageNotification(sender: sender, message: message);
  }
}