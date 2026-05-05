import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/message.dart';

class AgentPresetService {
  static const String _presetsKey = 'agent_presets';
  
  Future<List<AgentPreset>> loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_presetsKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => AgentPreset.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> savePresets(List<AgentPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = presets.map((p) => p.toJson()).toList();
    await prefs.setString(_presetsKey, json.encode(jsonList));
  }
  
  Future<void> addPreset(AgentPreset preset) async {
    final presets = await loadPresets();
    presets.add(preset);
    await savePresets(presets);
  }
  
  Future<void> updatePreset(AgentPreset preset) async {
    final presets = await loadPresets();
    final index = presets.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      presets[index] = preset;
      await savePresets(presets);
    }
  }
  
  Future<void> deletePreset(String id) async {
    final presets = await loadPresets();
    presets.removeWhere((p) => p.id == id);
    await savePresets(presets);
  }
  
  Future<AgentPreset?> getPreset(String id) async {
    final presets = await loadPresets();
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
