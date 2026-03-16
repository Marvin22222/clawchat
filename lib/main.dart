import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Push Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const ClawChatApp());
}
