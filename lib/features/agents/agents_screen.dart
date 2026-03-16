import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh agents list
              auth.connect();
            },
          ),
        ],
      ),
      body: auth.ws.availableAgents.isEmpty
          ? _EmptyState(isDark: isDark)
          : _AgentsList(
              agents: auth.ws.availableAgents,
              selectedAgent: auth.selectedAgent,
              isDark: isDark,
              onAgentTap: (agent) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(initialAgent: agent),
                  ),
                );
              },
              onAgentSelect: (agent) {
                auth.setSelectedAgent(agent);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                Icons.smart_toy_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Keine Agents verfügbar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDark
                    : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verbinde dich mit dem Gateway um\nverfügbare Agents zu sehen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                auth.connect();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentsList extends StatelessWidget {
  final List<String> agents;
  final String? selectedAgent;
  final bool isDark;
  final Function(String) onAgentTap;
  final Function(String) onAgentSelect;

  const _AgentsList({
    required this.agents,
    required this.selectedAgent,
    required this.isDark,
    required this.onAgentTap,
    required this.onAgentSelect,
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
      return Icons.code;
    }
    if (lower.contains('research') || lower.contains('search')) {
      return Icons.search;
    }
    if (lower.contains('write') || lower.contains('content')) {
      return Icons.edit_document;
    }
    if (lower.contains('analyst') || lower.contains('data')) {
      return Icons.analytics;
    }
    if (lower.contains('image') || lower.contains('vision')) {
      return Icons.image;
    }
    if (lower.contains('voice') || lower.contains('audio')) {
      return Icons.mic;
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

  const _AgentCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
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
                        isSelected ? Icons.star : Icons.star_border,
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
                      Icons.arrow_forward_ios,
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
