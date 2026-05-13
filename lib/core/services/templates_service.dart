import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/message_template.dart';

/// Service for managing message templates / canned responses
class TemplatesService {
  static const String _customTemplatesKey = 'custom_message_templates';

  /// Get default templates (built-in)
  static List<MessageTemplate> getDefaultTemplates() {
    return MessageTemplate.defaultTemplates;
  }

  /// Get all default templates
  static List<MessageTemplate> get defaultTemplates => getDefaultTemplates();

  /// Get custom templates from storage
  static Future<List<MessageTemplate>> getCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_customTemplatesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => MessageTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all templates (defaults + custom)
  static Future<List<MessageTemplate>> getAllTemplates() async {
    final defaults = getDefaultTemplates();
    final custom = await getCustomTemplates();
    return [...defaults, ...custom];
  }

  /// Save a new custom template
  static Future<void> saveTemplate(MessageTemplate template) async {
    final templates = await getCustomTemplates();
    
    // Check if template with same ID exists (update) or new (add)
    final existingIndex = templates.indexWhere((t) => t.id == template.id);
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.add(template);
    }
    
    await _saveCustomTemplates(templates);
  }

  /// Delete a custom template by ID
  static Future<void> deleteTemplate(String id) async {
    final templates = await getCustomTemplates();
    templates.removeWhere((t) => t.id == id);
    await _saveCustomTemplates(templates);
  }

  /// Update an existing custom template
  static Future<void> updateTemplate(MessageTemplate template) async {
    final templates = await getCustomTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      templates[index] = template;
      await _saveCustomTemplates(templates);
    }
  }

  /// Get templates by category
  static Future<List<MessageTemplate>> getTemplatesByCategory(String category) async {
    final all = await getAllTemplates();
    if (category == 'all' || category == 'custom') {
      // 'custom' shows all custom templates
      if (category == 'custom') {
        return all.where((t) => t.isCustom).toList();
      }
      return all;
    }
    return all.where((t) => t.category == category).toList();
  }

  /// Find template by shortcut (e.g., "/code")
  static Future<MessageTemplate?> findByShortcut(String shortcut) async {
    final all = await getAllTemplates();
    try {
      return all.firstWhere((t) => t.shortcut?.toLowerCase() == shortcut.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Generate a unique ID for new templates
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get count of templates
  static Future<int> getTemplateCount() async {
    final all = await getAllTemplates();
    return all.length;
  }

  // Private helper to persist custom templates
  static Future<void> _saveCustomTemplates(List<MessageTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_customTemplatesKey, json.encode(jsonList));
  }
}