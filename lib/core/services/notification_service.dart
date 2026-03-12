import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  bool _isEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get isEnabled => _isEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  void setEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    notifyListeners();
  }

  // In a real app, this would use flutter_local_notifications
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isEnabled) return;
    
    debugPrint('Notification: $title - $body');
    // Implementation would go here
  }

  Future<void> showMessageNotification({
    required String sender,
    required String message,
  }) async {
    await showNotification(
      title: sender,
      body: message.length > 100 
          ? '${message.substring(0, 100)}...' 
          : message,
    );
  }

  Future<void> showTaskNotification({
    required String taskName,
    required String status,
  }) async {
    await showNotification(
      title: 'Task $status',
      body: taskName,
    );
  }
}
