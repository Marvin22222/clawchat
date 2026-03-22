import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    final notificationService = NotificationService();
    await notificationService.initialize();
  }
  
  runApp(const ClawChatApp());
}
