import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../models/agent_session.dart';
import '../../models/agent_status.dart';
import 'status_indicator.dart';

/// Card widget displaying agent status, name, and current task
class AgentCard extends StatelessWidget {
  final AgentSession agent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AgentCard({
    super.key,
    required this.agent,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Avatar + Name + Status
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        agent.avatarEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: TextStyle(
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (agent.role != null)
                          Text(
                            agent.role!,
                            style: TextStyle(
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  StatusIndicator(status: agent.status, size: 20),
                ],
              ),

              const SizedBox(height: 12),

              // Current task
              if (agent.currentTask != null)
                Text(
                  agent.currentTask!,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Progress bar
              if (agent.status == AgentStatus.busy || agent.progress > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(agent.progress * 100).toInt()}%',
                          style: TextStyle(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: agent.progress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? AppColors.bgDarkTertiary
                            : AppColors.bgLightTertiary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(agent.status, isDark),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Footer: steps count + duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (agent.steps.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 14,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${agent.steps.length} steps',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  if (agent.startedAt != null)
                    Text(
                      agent.durationString,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(AgentStatus status, bool isDark) {
    switch (status) {
      case AgentStatus.live:
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
      case AgentStatus.busy:
        return isDark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04);
      case AgentStatus.idle:
        return isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
      case AgentStatus.error:
        return isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    }
  }
}
