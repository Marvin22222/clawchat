import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_info_service.dart';

/// Manager for exporting, importing, and resetting app data
class AppDataManager {
  static const String _chatFolder = 'chats';
  static const String _attachmentsFolder = 'attachments';
  static const String _backupFileName = 'clawchat_backup.json';
  
  /// Export all app data as JSON
  static Future<String?> exportAllData() async {
    try {
      final exportData = await _gatherExportData();
      final jsonString = jsonEncode(exportData);
      
      // Save to temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'clawchat_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ClawChat Backup',
      );
      
      return file.path;
    } catch (e) {
      return null;
    }
  }
  
  /// Import data from a backup JSON file
  static Future<bool> importFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup structure
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        return false;
      }
      
      // Import chats if present
      if (data.containsKey('chats')) {
        await _importChats(data['chats'] as List);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Reset app to defaults (keeps app functional, clears user data)
  static Future<void> resetToDefaults() async {
    await StorageInfoService.clearAll();
    await _clearPreferences();
  }
  
  /// Get storage breakdown
  static Future<Map<String, int>> getStorageBreakdown() async {
    return {
      'cache': await StorageInfoService.getCacheSize(),
      'messages': await StorageInfoService.getMessagesSize(),
      'attachments': await StorageInfoService.getAttachmentsSize(),
      'total': await StorageInfoService.getTotalSize(),
    };
  }
  
  // Private helpers
  
  static Future<Map<String, dynamic>> _gatherExportData() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Gather chats
    final chatsDir = Directory('${appDocDir.path}/$_chatFolder');
    final chats = <Map<String, dynamic>>[];
    
    if (await chatsDir.exists()) {
      try {
        await for (final entity in chatsDir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            try {
              final content = await entity.readAsString();
              final chatData = jsonDecode(content);
              if (chatData is Map<String, dynamic>) {
                chats.add(chatData);
              }
            } catch (e) {
              // Skip invalid files
            }
          }
        }
      } catch (e) {
        // Permission denied
      }
    }
    
    // Gather attachments metadata (not actual files for size reasons)
    final attachmentsDir = Directory('${appDocDir.path}/$_attachmentsFolder');
    final attachmentsMeta = <Map<String, dynamic>>[];
    
    if (await attachmentsDir.exists()) {
      try {
        await for (final entity in attachmentsDir.list(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            attachmentsMeta.add({
              'name': entity.path.split('/').last,
              'path': entity.path,
              'size': stat.size,
              'modified': stat.modified.toIso8601String(),
            });
          }
        }
      } catch (e) {
        // Permission denied
      }
    }
    
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'app': 'ClawChat',
      'chats': chats,
      'attachmentsCount': attachmentsMeta.length,
      'attachmentsMeta': attachmentsMeta,
    };
  }
  
  static Future<void> _importChats(List chats) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final chatsDir = Directory('${appDocDir.path}/$_chatFolder');
    
    if (!await chatsDir.exists()) {
      await chatsDir.create(recursive: true);
    }
    
    for (final chat in chats) {
      if (chat is Map<String, dynamic>) {
        final chatId = chat['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        final file = File('${chatsDir.path}/$chatId.json');
        await file.writeAsString(jsonEncode(chat));
      }
    }
  }
  
  static Future<void> _clearPreferences() async {
    // This would need SharedPreferences or equivalent
    // For now, just a placeholder - actual implementation depends on auth provider
  }
}