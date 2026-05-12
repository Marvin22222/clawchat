import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Deferred initialization - non-critical services don't block startup
  // Critical: None (auth is lazy-loaded on first frame)
  
  runApp(const ClawChatApp());
}
