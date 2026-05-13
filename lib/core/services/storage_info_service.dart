import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service to get storage information and manage app data storage
class StorageInfoService {
  static const String _chatFolder = 'chats';
  static const String _attachmentsFolder = 'attachments';
  static const String _cacheFolder = 'cache';
  
  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final directory = await _getAppDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheFolder');
      if (await cacheDir.exists()) {
        return await _getFolderSize(cacheDir);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get messages/storage size in bytes
  static Future<int> getMessagesSize() async {
    try {
      final directory = await _getAppDirectory();
      final chatDir = Directory('${directory.path}/$_chatFolder');
      if (await chatDir.exists()) {
        return await _getFolderSize(chatDir);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get attachments size in bytes
  static Future<int> getAttachmentsSize() async {
    try {
      final directory = await _getAppDirectory();
      final attachDir = Directory('${directory.path}/$_attachmentsFolder');
      if (await attachDir.exists()) {
        return await _getFolderSize(attachDir);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get total app storage size in bytes
  static Future<int> getTotalSize() async {
    final cacheSize = await getCacheSize();
    final messagesSize = await getMessagesSize();
    final attachmentsSize = await getAttachmentsSize();
    return cacheSize + messagesSize + attachmentsSize;
  }
  
  /// Clear cache directory
  static Future<void> clearCache() async {
    try {
      final directory = await _getAppDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheFolder');
      if (await cacheDir.exists()) {
        await _deleteDirectoryContents(cacheDir);
      }
    } catch (e) {
      // Silently fail - cache clear is non-critical
    }
  }
  
  /// Clear messages/chats directory
  static Future<void> clearMessages() async {
    try {
      final directory = await _getAppDirectory();
      final chatDir = Directory('${directory.path}/$_chatFolder');
      if (await chatDir.exists()) {
        await _deleteDirectoryContents(chatDir);
      }
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Clear attachments directory
  static Future<void> clearAttachments() async {
    try {
      final directory = await _getAppDirectory();
      final attachDir = Directory('${directory.path}/$_attachmentsFolder');
      if (await attachDir.exists()) {
        await _deleteDirectoryContents(attachDir);
      }
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Clear all app data (cache, messages, attachments)
  static Future<void> clearAll() async {
    await clearCache();
    await clearMessages();
    await clearAttachments();
  }
  
  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int suffixIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    
    if (suffixIndex == 0) {
      return '${size.round()} ${suffixes[suffixIndex]}';
    }
    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
  
  // Private helpers
  
  static Future<Directory> _getAppDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir;
  }
  
  static Future<int> _getFolderSize(Directory directory) async {
    int totalSize = 0;
    
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      // Permission denied or other errors
    }
    
    return totalSize;
  }
  
  static Future<void> _deleteDirectoryContents(Directory directory) async {
    try {
      await for (final entity in directory.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      // Permission denied or other errors
    }
  }
}