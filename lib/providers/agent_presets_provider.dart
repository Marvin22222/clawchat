import 'package:flutter/foundation.dart';
import '../core/services/agent_preset_service.dart';
import '../models/message.dart';

enum ModelType { minimax, claude, gpt }

extension ModelTypeExtension on ModelType {
  String get displayName {
    switch (this) {
      case ModelType.minimax:
        return 'MiniMax';
      case ModelType.claude:
        return 'Claude';
      case ModelType.gpt:
        return 'ChatGPT';
    }
  }

  String get value {
    switch (this) {
      case ModelType.minimax:
        return 'minimax';
      case ModelType.claude:
        return 'claude';
      case ModelType.gpt:
        return 'gpt';
    }
  }

  static ModelType fromString(String value) {
    switch (value) {
      case 'claude':
        return ModelType.claude;
      case 'gpt':
        return ModelType.gpt;
      default:
        return ModelType.minimax;
    }
  }
}

class AgentPresetsProvider extends ChangeNotifier {
  final AgentPresetService _service = AgentPresetService();
  
  List<AgentPreset> _presets = [];
  bool _isLoading = false;
  String? _activePresetId;

  List<AgentPreset> get presets => _presets;
  bool get isLoading => _isLoading;
  String? get activePresetId => _activePresetId;
  AgentPreset? get activePreset => _activePresetId != null 
      ? _presets.where((p) => p.id == _activePresetId).firstOrNull 
      : null;

  AgentPresetsProvider() {
    loadPresets();
  }

  Future<void> loadPresets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _presets = await _service.loadPresets();
    } catch (e) {
      _presets = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPreset({
    required String name,
    required String agentId,
    String? systemPrompt,
    Map<String, dynamic>? customParams,
    ModelType modelType = ModelType.minimax,
  }) async {
    final preset = AgentPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      agentId: agentId,
      systemPrompt: systemPrompt,
      customParams: {
        ...?customParams,
        'modelType': modelType.value,
      },
      createdAt: DateTime.now(),
    );

    await _service.addPreset(preset);
    _presets.add(preset);
    notifyListeners();
  }

  Future<void> updatePreset({
    required String id,
    String? name,
    String? agentId,
    String? systemPrompt,
    Map<String, dynamic>? customParams,
    ModelType? modelType,
  }) async {
    final index = _presets.indexWhere((p) => p.id == id);
    if (index < 0) return;

    final oldPreset = _presets[index];
    final updatedPreset = oldPreset.copyWith(
      name: name,
      agentId: agentId,
      systemPrompt: systemPrompt,
      customParams: {
        ...?oldPreset.customParams,
        if (modelType != null) 'modelType': modelType.value,
        ...?customParams,
      },
    );

    await _service.updatePreset(updatedPreset);
    _presets[index] = updatedPreset;
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await _service.deletePreset(id);
    _presets.removeWhere((p) => p.id == id);
    if (_activePresetId == id) {
      _activePresetId = null;
    }
    notifyListeners();
  }

  void setActivePreset(String? presetId) {
    _activePresetId = presetId;
    notifyListeners();
  }

  void clearActivePreset() {
    _activePresetId = null;
    notifyListeners();
  }

  ModelType getPresetModelType(AgentPreset preset) {
    final modelStr = preset.customParams?['modelType'] as String?;
    return modelStr != null 
        ? ModelTypeExtension.fromString(modelStr) 
        : ModelType.minimax;
  }
}