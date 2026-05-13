import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'app.dart';
import 'core/services/localization_service.dart';

/// Configure cached_network_image memory and disk cache limits
void _configureImageCache() {
  // Override default cache manager with custom config
  DefaultCacheManager.instance = DefaultCacheManager(
    // Disk cache: max 100MB
    maxCacheSize: 100 * 1024 * 1024,
    // Max age: 7 days
    maxAge: const Duration(days: 7),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize localization
  await LocalizationService.init();
  
  // Configure image caching
  _configureImageCache();
  
  // Deferred initialization - non-critical services don't block startup
  // Critical: None (auth is lazy-loaded on first frame)
  
  runApp(const ClawChatApp());
}