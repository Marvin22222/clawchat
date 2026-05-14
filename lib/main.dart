import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await LocalizationService.init();

  runApp(const ClawChatApp());
}