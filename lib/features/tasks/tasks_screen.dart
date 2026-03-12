import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class Task {
  final String id;
  final String name;
  final String status; // 'pending', 'running', 'completed', 'failed'
  final DateTime? lastRun;
  final String? cronExpression;

  Task({
    required this.id,
    required this.name,
    required this.status,
    this.lastRun,
    this.cronExpression,
  });
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  // Demo tasks - in real app these would come from the WebSocket
  final List<Task> _demoTasks = [
    Task(
      id: '1',
      name: 'Tradingnews',
      status: 'completed',
      lastRun: DateTime.now().subtract(const Duration(hours: 2)),
      cronExpression: '0 9 * * *',
    ),
    Task(
      id: '2',
      name: 'AI News Daily',
      status: 'completed',
      lastRun: DateTime.now().subtract(const Duration(hours: 3)),
      cronExpression: '30 8 * * *',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Cron Jobs'),
      ),
      body: _demoTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 64,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Keine aktiven Tasks',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _demoTasks.length,
              itemBuilder: (context, index) {
                final task = _demoTasks[index];
                return _TaskCard(
                  task: task,
                  isDark: isDark,
                );
              },
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;

  const _TaskCard({
    required this.task,
    required this.isDark,
  });

  Color get _statusColor {
    switch (task.status) {
      case 'completed':
        return AppColors.success;
      case 'running':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData get _statusIcon {
    switch (task.status) {
      case 'completed':
        return Icons.check_circle;
      case 'running':
        return Icons.play_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                _statusIcon,
                color: _statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textDark
                          : AppColors.textLight,
                    ),
                  ),
                  if (task.cronExpression != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.cronExpression!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.status == 'running')
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (task.lastRun != null)
              Text(
                _formatTime(task.lastRun!),
                style: TextStyle(
                  fontSize: 12,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
