import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../widgets/empty_state.dart';
import 'models/task_model.dart';
import 'providers/task_provider.dart';
import '../../widgets/animations/skeleton_loaders.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Lade Demo-Daten beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      if (provider.allTasks.isEmpty) {
        provider.loadDemoTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Cron Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              context.read<TaskProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              // Filter Chips
              _FilterChips(
                currentFilter: taskProvider.filterStatus,
                onFilterChanged: taskProvider.setFilter,
                runningCount: taskProvider.runningCount,
                completedCount: taskProvider.completedCount,
                failedCount: taskProvider.failedCount,
                pendingCount: taskProvider.pendingCount,
                isDark: isDark,
              ),
              
              // Task List
              Expanded(
                child: _buildTaskList(taskProvider, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider, bool isDark) {
    if (taskProvider.isLoading) {
      return const TasksListSkeleton();
    }

    if (taskProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fehler beim Laden',
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            TextButton(
              onPressed: taskProvider.refresh,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final tasks = taskProvider.tasks;

    if (tasks.isEmpty) {
      String title;
      String subtitle;
      if (taskProvider.filterStatus != null) {
        title = 'Keine Aufgaben';
        subtitle = 'Versuche einen anderen Filter';
      } else {
        title = 'Alle erledigt! 🎉';
        subtitle = 'Deine geplanten Tasks erscheinen hier';
      }
      return BetterEmptyState(
        icon: Iconsax.task_alt,
        title: title,
        subtitle: subtitle,
        isDark: isDark,
        animationType: BetterEmptyStateAnimationType.pulse,
      );
    }

    return RefreshIndicator(
      onRefresh: taskProvider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            isDark: isDark,
            onTap: () => _showTaskDetails(context, task),
          );
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TaskStatus? currentFilter;
  final Function(TaskStatus?) onFilterChanged;
  final int runningCount;
  final int completedCount;
  final int failedCount;
  final int pendingCount;
  final bool isDark;

  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.runningCount,
    required this.completedCount,
    required this.failedCount,
    required this.pendingCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Alle',
            count: runningCount + completedCount + failedCount + pendingCount,
            isSelected: currentFilter == null,
            color: AppColors.primary,
            onTap: () => onFilterChanged(null),
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Läuft',
            count: runningCount,
            isSelected: currentFilter == TaskStatus.running,
            color: AppColors.info,
            onTap: () => onFilterChanged(TaskStatus.running),
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Fertig',
            count: completedCount,
            isSelected: currentFilter == TaskStatus.completed,
            color: AppColors.success,
            onTap: () => onFilterChanged(TaskStatus.completed),
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Fehler',
            count: failedCount,
            isSelected: currentFilter == TaskStatus.failed,
            color: AppColors.error,
            onTap: () => onFilterChanged(TaskStatus.failed),
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Ausstehend',
            count: pendingCount,
            isSelected: currentFilter == TaskStatus.pending,
            color: AppColors.textDarkSecondary,
            onTap: () => onFilterChanged(TaskStatus.pending),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color : (isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
    this.onTap,
  });

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.running:
        return AppColors.info;
      case TaskStatus.failed:
        return AppColors.error;
      case TaskStatus.pending:
        return AppColors.textDarkSecondary;
    }
  }

  IconData get _statusIcon {
    switch (task.status) {
      case TaskStatus.completed:
        return Iconsax.tick_square_circle;
      case TaskStatus.running:
        return Iconsax.play_circle;
      case TaskStatus.failed:
        return Iconsax.warning_2;
      case TaskStatus.pending:
        return Iconsax.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (task.agent != null) ...[
                          Icon(
                            Iconsax.robot_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.agent!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (task.cronExpression != null) ...[
                          Icon(
                            Iconsax.clock,
                            size: 12,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                          const SizedBox(width: 4),
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
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (task.status == TaskStatus.running)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      _formatTime(task.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    task.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: _statusColor,
                      fontWeight: FontWeight.w500,
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

class TaskDetailsSheet extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsSheet({super.key, required this.task});

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.running:
        return AppColors.info;
      case TaskStatus.failed:
        return AppColors.error;
      case TaskStatus.pending:
        return AppColors.textDarkSecondary;
    }
  }

  IconData get _statusIcon {
    switch (task.status) {
      case TaskStatus.completed:
        return Iconsax.tick_square_circle;
      case TaskStatus.running:
        return Iconsax.play_circle;
      case TaskStatus.failed:
        return Iconsax.warning_2;
      case TaskStatus.pending:
        return Iconsax.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Icon(
                        _statusIcon,
                        color: _statusColor,
                        size: 24,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                          ),
                          Text(
                            task.status.displayName,
                            style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Details
                _DetailRow(
                  icon: Iconsax.finger_print,
                  label: 'Task ID',
                  value: task.id,
                  isDark: isDark,
                ),
                if (task.agent != null)
                  _DetailRow(
                    icon: Iconsax.robot_outlined,
                    label: 'Agent',
                    value: task.agent!,
                    isDark: isDark,
                  ),
                _DetailRow(
                  icon: Iconsax.calendar_1,
                  label: 'Erstellt',
                  value: _formatDateTime(task.createdAt),
                  isDark: isDark,
                ),
                if (task.completedAt != null)
                  _DetailRow(
                    icon: Iconsax.tick_square_circle_outline,
                    label: 'Abgeschlossen',
                    value: _formatDateTime(task.completedAt!),
                    isDark: isDark,
                  ),
                if (task.duration != null)
                  _DetailRow(
                    icon: Iconsax.timer_1,
                    label: 'Dauer',
                    value: _formatDuration(task.duration!),
                    isDark: isDark,
                  ),
                if (task.cronExpression != null)
                  _DetailRow(
                    icon: Iconsax.clock,
                    label: 'Zeitplan',
                    value: task.cronExpression!,
                    isDark: isDark,
                  ),
                if (task.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Iconsax.warning_2_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            task.errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.lg),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Task neu starten
                          Navigator.pop(context);
                        },
                        icon: const Icon(Iconsax.arrow_clockwise),
                        label: const Text('Neustarten'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.close_square),
                        label: const Text('Schließen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) {
      return '${d.inSeconds}s';
    } else if (d.inHours < 1) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    } else {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
