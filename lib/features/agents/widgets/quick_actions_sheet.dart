import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_session.dart';

/// Quick actions menu shown on long press of an agent card
class QuickActionsSheet extends StatelessWidget {
  final AgentSession agent;
  final VoidCallback? onSendMessage;
  final VoidCallback? onCancelTask;
  final VoidCallback? onViewHistory;
  final VoidCallback? onResetAgent;

  const QuickActionsSheet({
    super.key,
    required this.agent,
    this.onSendMessage,
    this.onCancelTask,
    this.onViewHistory,
    this.onResetAgent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.border : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with agent info
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      agent.avatarEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: TextStyle(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        agent.role ?? 'Agent',
                        style: TextStyle(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
          
          // Actions list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Send message
                _ActionTile(
                  icon: Iconsax.message_text_outlined,
                  iconColor: AppColors.primary,
                  title: 'Send Message',
                  subtitle: 'Send a message to this agent',
                  onTap: () {
                    Navigator.pop(context);
                    onSendMessage?.call();
                  },
                ),
                
                // Cancel task (only if busy or live)
                if (agent.status.name == 'busy' || agent.status.name == 'live')
                  _ActionTile(
                    icon: Iconsax.close_square,
                    iconColor: AppColors.warning,
                    title: 'Cancel Task',
                    subtitle: 'Stop the current task',
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelConfirmation(context);
                    },
                    isDestructive: true,
                  ),
                
                // View history
                _ActionTile(
                  icon: Iconsax.clock_1,
                  iconColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  title: 'View History',
                  subtitle: 'See past activity and conversations',
                  onTap: () {
                    Navigator.pop(context);
                    onViewHistory?.call();
                  },
                ),
                
                // Reset agent
                _ActionTile(
                  icon: Iconsax.refresh,
                  iconColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  title: 'Reset Agent',
                  subtitle: 'Clear state and restart',
                  onTap: () {
                    Navigator.pop(context);
                    _showResetConfirmation(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
          
          // Cancel button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  side: BorderSide(
                    color: isDark ? AppColors.border : AppColors.borderLight,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
          
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancel Task?',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        content: Text(
          'This will stop the current task for ${agent.name}.',
          style: TextStyle(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Running',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCancelTask?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reset Agent?',
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        content: Text(
          'This will clear all state and reset ${agent.name}. This cannot be undone.',
          style: TextStyle(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onResetAgent?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? AppColors.error
              : (isDark ? AppColors.textDark : AppColors.textLight),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Iconsax.chevron_right,
        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
      ),
    );
  }
}