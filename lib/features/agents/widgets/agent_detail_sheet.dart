import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_session.dart';
import '../../../models/agent_status.dart';
import 'status_indicator.dart';
import 'agent_avatar.dart';

/// Bottom sheet showing detailed agent information with activity timeline
class AgentDetailSheet extends StatelessWidget {
  final AgentSession agent;
  final VoidCallback? onViewChat;
  final VoidCallback? onCancelTask;
  final VoidCallback? onSendMessage;

  const AgentDetailSheet({
    super.key,
    required this.agent,
    this.onViewChat,
    this.onCancelTask,
    this.onSendMessage,
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
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Name + Status
                  Row(
                    children: [
                      AgentAvatar(role: agent.role, size: AgentAvatarSize.xl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: TextStyle(
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agent.role ?? 'Unknown',
                              style: TextStyle(
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusIndicator(status: agent.status, size: 24),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Current task section
                  if (agent.currentTask != null) ...[
                    _SectionHeader(title: 'Current Task'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        agent.currentTask!,
                        style: TextStyle(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Progress section
                  if (agent.progress > 0 || agent.status == AgentStatus.busy) ...[
                    _SectionHeader(title: 'Progress'),
                    const SizedBox(height: 8),
                    _ProgressSection(agent: agent, isDark: isDark),
                    const SizedBox(height: 24),
                  ],

                  // Steps breakdown
                  if (agent.steps.isNotEmpty) ...[
                    _SectionHeader(title: 'Steps Breakdown'),
                    const SizedBox(height: 8),
                    _StepsList(steps: agent.steps, isDark: isDark),
                    const SizedBox(height: 24),
                  ],

                  // Activity timeline
                  _SectionHeader(title: 'Activity Timeline'),
                  const SizedBox(height: 8),
                  _ActivityTimeline(agent: agent, isDark: isDark),

                  const SizedBox(height: 24),

                  // Action buttons
                  _ActionButtons(
                    onViewChat: onViewChat ?? () => Navigator.pop(context),
                    onCancelTask: onCancelTask ?? () => Navigator.pop(context),
                    onSendMessage: onSendMessage ?? () => Navigator.pop(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final AgentSession agent;
  final bool isDark;

  const _ProgressSection({required this.agent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(agent.progress * 100).toInt()}%',
                style: TextStyle(
                  color: _getStatusColor(agent.status),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                agent.status == AgentStatus.busy
                    ? 'In Progress'
                    : agent.status == AgentStatus.live
                        ? 'Active'
                        : 'Completed',
                style: TextStyle(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: agent.progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(agent.status)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AgentStatus status) {
    return Color(status.darkColor);
  }
}

class _StepsList extends StatelessWidget {
  final List<String> steps;
  final bool isDark;

  const _StepsList({required this.steps, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isLast = index == steps.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: index == 0 ? 12 : 8,
              bottom: isLast ? 12 : 0,
            ),
            child: Row(
              children: [
                // Checkmark circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Step text
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final AgentSession agent;
  final bool isDark;

  const _ActivityTimeline({required this.agent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Generate mock timeline events from agent data
    final events = _generateTimelineEvents();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(events.length, (index) {
          final event = events[index];
          final isLast = index == events.length - 1;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: index == 0 ? 12 : 8,
              bottom: isLast ? 12 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: isDark ? AppColors.border : AppColors.borderLight,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Event content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.timestamp,
                          style: TextStyle(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<_TimelineEvent> _generateTimelineEvents() {
    final now = DateTime.now();
    final startedAt = agent.startedAt ?? now.subtract(const Duration(hours: 1));

    return [
      _TimelineEvent(
        title: 'Agent ${agent.status == AgentStatus.idle ? 'idle' : 'started'}',
        timestamp: _formatTime(startedAt),
        type: _EventType.start,
      ),
      if (agent.currentTask != null)
        _TimelineEvent(
          title: 'Task: ${agent.currentTask}',
          timestamp: _formatTime(startedAt.add(const Duration(minutes: 1))),
          type: _EventType.task,
        ),
      if (agent.steps.isNotEmpty)
        _TimelineEvent(
          title: '${agent.steps.length} steps completed',
          timestamp: _formatTime(now.subtract(const Duration(minutes: 5))),
          type: _EventType.step,
        ),
      _TimelineEvent(
        title: agent.status == AgentStatus.live
            ? 'Currently responding'
            : agent.status == AgentStatus.busy
                ? 'Working...'
                : agent.status == AgentStatus.idle
                    ? 'Waiting for tasks'
                    : 'Error occurred',
        timestamp: 'Now',
        type: _EventType.current,
      ),
    ];
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getEventColor(_EventType type) {
    switch (type) {
      case _EventType.start:
        return AppColors.primary;
      case _EventType.task:
        return const Color(0xFF3B82F6);
      case _EventType.step:
        return const Color(0xFF22C55E);
      case _EventType.current:
        return Color(agent.status.darkColor);
    }
  }
}

enum _EventType { start, task, step, current }

class _TimelineEvent {
  final String title;
  final String timestamp;
  final _EventType type;

  _TimelineEvent({
    required this.title,
    required this.timestamp,
    required this.type,
  });
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onViewChat;
  final VoidCallback onCancelTask;
  final VoidCallback onSendMessage;
  final bool isDark;

  const _ActionButtons({
    required this.onViewChat,
    required this.onCancelTask,
    required this.onSendMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // View Chat button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('View Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              side: BorderSide(
                color: isDark ? AppColors.border : AppColors.borderLight,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Cancel button
        if (agent.status == AgentStatus.busy || agent.status == AgentStatus.live) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancelTask,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        // Send Message button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSendMessage,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}