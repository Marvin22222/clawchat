import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/agent_preset_service.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/animations/skeleton_loaders.dart';
import '../chat/chat_screen.dart';
import 'package:iconsax/iconsax.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final AgentPresetService _presetService = AgentPresetService();
  List<AgentPreset> _presets = [];
  bool _showPresets = false;
  bool _isLoadingAgents = false;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadAgentsWithSkeleton();
  }

  Future<void> _loadAgentsWithSkeleton() async {
    setState(() => _isLoadingAgents = true);
    // Simulate loading delay for skeleton demo
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoadingAgents = false);
    }
  }

  Future<void> _loadPresets() async {
    final presets = await _presetService.loadPresets();
    if (mounted) {
      setState(() => _presets = presets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showPresets ? Icons.smart_toy : Iconsax.bookmark),
            onPressed: () {
              setState(() => _showPresets = !_showPresets);
            },
            tooltip: _showPresets ? 'Agents' : 'Presets',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              auth.connect();
            },
          ),
        ],
      ),
      body: _isLoadingAgents ? const AgentsListSkeleton() : _showPresets ? _PresetsList(
        presets: _presets,
        isDark: isDark,
        onLoadPreset: _loadPreset,
        onDeletePreset: _deletePreset,
        onAddPreset: (_) => _addPreset(),
        availableAgents: auth.ws.availableAgents,
      ) : (auth.ws.availableAgents.isEmpty
          ? _EmptyState(isDark: isDark, onRefresh: () => auth.connect())
          : _AgentsList(
              agents: auth.ws.availableAgents,
              selectedAgent: auth.selectedAgent,
              isDark: isDark,
              onAgentTap: (agent) {
                Navigator.push(
                  context,
                  AppPageTransitions.fadeSlide(
                    page: ChatScreen(initialAgent: agent),
                  ),
                );
              },
              onAgentSelect: (agent) {
                auth.setSelectedAgent(agent);
              },
              onAgentLongPress: (agent) => _showSavePresetDialog(context, agent),
            )),
    );
  }

  Future<void> _showSavePresetDialog(BuildContext context, String agent) async {
    final nameController = TextEditingController();
    final systemPromptController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: Text(
          'Preset speichern',
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. "Mein Coding Agent"',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: systemPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'System Prompt (optional)',
                hintText: 'Zusätzliche Anweisungen...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final preset = AgentPreset(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                agentId: agent,
                systemPrompt: systemPromptController.text.trim().isEmpty ? null : systemPromptController.text.trim(),
                createdAt: DateTime.now(),
              );
              await _presetService.addPreset(preset);
              await _loadPresets();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _loadPreset(AgentPreset preset) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: ChatScreen(initialAgent: preset.agentId),
      ),
    );
  }

  Future<void> _deletePreset(String id) async {
    await _presetService.deletePreset(id);
    await _loadPresets();
  }

  Future<void> _addPreset() async {
    // Do nothing - handled by long press on agent
  }
}

class _PresetsList extends StatelessWidget {
  final List<AgentPreset> presets;
  final bool isDark;
  final Function(AgentPreset) onLoadPreset;
  final Function(String) onDeletePreset;
  final Function(String) onAddPreset;
  final List<String> availableAgents;

  const _PresetsList({
    required this.presets,
    required this.isDark,
    required this.onLoadPreset,
    required this.onDeletePreset,
    required this.onAddPreset,
    required this.availableAgents,
  });

  IconData _getAgentIcon(String agentId) {
    final lower = agentId.toLowerCase();
    if (lower.contains('code') || lower.contains('dev')) return Iconsax.code;
    if (lower.contains('research') || lower.contains('search')) return Iconsax.search_normal_1;
    if (lower.contains('write') || lower.contains('content')) return Icons.edit_document;
    if (lower.contains('analyst') || lower.contains('data')) return Iconsax.chart;
    if (lower.contains('image') || lower.contains('vision')) return Iconsax.image;
    if (lower.contains('voice') || lower.contains('audio')) return Iconsax.microphone;
    return Icons.smart_toy;
  }

  Color _getAgentColor(String agentId) {
    final lower = agentId.toLowerCase();
    if (lower.contains('code') || lower.contains('dev')) return AppColors.success;
    if (lower.contains('research') || lower.contains('search')) return AppColors.info;
    if (lower.contains('write') || lower.contains('content')) return AppColors.secondary;
    if (lower.contains('analyst') || lower.contains('data')) return AppColors.warning;
    if (lower.contains('image') || lower.contains('vision')) return Colors.pink;
    if (lower.contains('voice') || lower.contains('audio')) return Colors.orange;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Keine Presets gespeichert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lange auf einen Agenten drücken\num ein Preset zu speichern',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return _PresetCard(
          preset: preset,
          isDark: isDark,
          agentIcon: _getAgentIcon(preset.agentId),
          agentColor: _getAgentColor(preset.agentId),
          onTap: () => onLoadPreset(preset),
          onDelete: () => onDeletePreset(preset.id),
          onEdit: () => _showEditPresetDialog(context, preset),
        );
      },
    );
  }

  Future<void> _showEditPresetDialog(BuildContext context, AgentPreset preset) async {
    final nameController = TextEditingController(text: preset.name);
    final systemPromptController = TextEditingController(text: preset.systemPrompt ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: Text(
          'Preset bearbeiten',
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: systemPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'System Prompt (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              // Update via provider would go here
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final AgentPreset preset;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final IconData? agentIcon;
  final Color? agentColor;

  const _PresetCard({
    required this.preset,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.agentIcon,
    this.agentColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = agentIcon ?? Iconsax.bookmark;
    final color = agentColor ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agent: ${preset.agentId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                      if (preset.systemPrompt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          preset.systemPrompt!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Iconsax.edit, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                        onPressed: onEdit,
                        tooltip: 'Bearbeiten',
                        iconSize: 20,
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Preset löschen?'),
                            content: Text('"${preset.name}" wirklich löschen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Abbrechen'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onDelete();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Löschen', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRefresh;

  const _EmptyState({required this.isDark, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BetterEmptyState(
      icon: Icons.smart_toy_outlined,
      title: 'Verbinde dich mit einem Gateway um Agenten zu sehen',
      subtitle: 'Deine verfügbaren Agents erscheinen hier',
      actionLabel: 'Erneut versuchen',
      onAction: onRefresh,
      isDark: isDark,
      animationType: BetterEmptyStateAnimationType.bounce,
    );
  }
}

class _AgentsList extends StatelessWidget {
  final List<String> agents;
  final String? selectedAgent;
  final bool isDark;
  final Function(String) onAgentTap;
  final Function(String) onAgentSelect;
  final Function(String)? onAgentLongPress;

  const _AgentsList({
    required this.agents,
    required this.selectedAgent,
    required this.isDark,
    required this.onAgentTap,
    required this.onAgentSelect,
    this.onAgentLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        final isSelected = agent == selectedAgent;
        
        return _AgentCard(
          name: agent,
          description: _getAgentDescription(agent),
          icon: _getAgentIcon(agent),
          iconColor: _getAgentColor(agent),
          isDark: isDark,
          isSelected: isSelected,
          onTap: () => onAgentTap(agent),
          onSelect: () => onAgentSelect(agent),
          onLongPress: onAgentLongPress != null ? () => onAgentLongPress!(agent) : null,
        );
      },
    );
  }

  String _getAgentDescription(String agent) {
    final lower = agent.toLowerCase();
    if (lower.contains('code') || lower.contains('dev')) {
      return 'Development & Coding Assistant';
    }
    if (lower.contains('research') || lower.contains('search')) {
      return 'Research & Web Search';
    }
    if (lower.contains('write') || lower.contains('content')) {
      return 'Content Creation & Writing';
    }
    if (lower.contains('analyst') || lower.contains('data')) {
      return 'Data Analysis & Insights';
    }
    if (lower.contains('general') || lower.contains('main')) {
      return 'General Purpose Assistant';
    }
    return 'AI Agent';
  }

  IconData _getAgentIcon(String agent) {
    final lower = agent.toLowerCase();
    if (lower.contains('code') || lower.contains('dev')) {
      return Iconsax.code;
    }
    if (lower.contains('research') || lower.contains('search')) {
      return Iconsax.search_normal_1;
    }
    if (lower.contains('write') || lower.contains('content')) {
      return Icons.edit_document;
    }
    if (lower.contains('analyst') || lower.contains('data')) {
      return Iconsax.chart;
    }
    if (lower.contains('image') || lower.contains('vision')) {
      return Iconsax.image;
    }
    if (lower.contains('voice') || lower.contains('audio')) {
      return Iconsax.microphone;
    }
    return Icons.smart_toy;
  }

  Color _getAgentColor(String agent) {
    final lower = agent.toLowerCase();
    if (lower.contains('code') || lower.contains('dev')) {
      return AppColors.success;
    }
    if (lower.contains('research') || lower.contains('search')) {
      return AppColors.info;
    }
    if (lower.contains('write') || lower.contains('content')) {
      return AppColors.secondary;
    }
    if (lower.contains('analyst') || lower.contains('data')) {
      return AppColors.warning;
    }
    if (lower.contains('image') || lower.contains('vision')) {
      return Colors.pink;
    }
    if (lower.contains('voice') || lower.contains('audio')) {
      return Colors.orange;
    }
    return AppColors.primary;
  }
}

class _AgentCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;

  const _AgentCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
    this.onLongPress,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: isSelected 
              ? AppColors.primary 
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Agent Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor,
                        iconColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Agent Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.small),
                              ),
                              child: const Text(
                                'Standard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isSelected ? Iconsax.star_1 : Icons.star_outline,
                        color: isSelected 
                            ? AppColors.warning 
                            : (isDark 
                                ? AppColors.textDarkSecondary 
                                : AppColors.textLightSecondary),
                      ),
                      onPressed: onSelect,
                      tooltip: isSelected 
                          ? 'Als Standard entfernen' 
                          : 'Als Standard setzen',
                    ),
                    Icon(
                      Iconsax.arrow_right_1,
                      size: 16,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
