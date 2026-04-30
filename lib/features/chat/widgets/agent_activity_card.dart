import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

enum AgentActivityStatus { idle, running, completed, error }

class AgentActivityCard extends StatefulWidget {
  final String agentName;
  final String? taskDescription;
  final AgentActivityStatus status;
  final double progress;
  final List<AgentStep> steps;
  final VoidCallback? onCancel;
  final bool isExpanded;

  const AgentActivityCard({
    super.key,
    required this.agentName,
    this.taskDescription,
    this.status = AgentActivityStatus.idle,
    this.progress = 0.0,
    this.steps = const [],
    this.onCancel,
    this.isExpanded = false,
  });

  @override
  State<AgentActivityCard> createState() => _AgentActivityCardState();
}

class _AgentActivityCardState extends State<AgentActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == AgentActivityStatus.running) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AgentActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == AgentActivityStatus.running) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return AppColors.textLightSecondary;
      case AgentActivityStatus.running:
        return AppColors.warning;
      case AgentActivityStatus.completed:
        return AppColors.success;
      case AgentActivityStatus.error:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return Icons.circle_outlined;
      case AgentActivityStatus.running:
        return Icons.play_circle_filled;
      case AgentActivityStatus.completed:
        return Icons.check_circle;
      case AgentActivityStatus.error:
        return Icons.error;
    }
  }

  String get _statusText {
    switch (widget.status) {
      case AgentActivityStatus.idle:
        return 'Idle';
      case AgentActivityStatus.running:
        return 'Running';
      case AgentActivityStatus.completed:
        return 'Completed';
      case AgentActivityStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Always visible
          InkWell(
            onTap: widget.steps.isNotEmpty
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Animated status indicator
                      widget.status == AgentActivityStatus.running
                          ? AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _statusColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _statusIcon,
                                      color: _statusColor,
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon,
                                color: _statusColor,
                                size: 20,
                              ),
                            ),
                      const SizedBox(width: AppSpacing.md),
                      // Agent info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.agentName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                            if (widget.taskDescription != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.taskDescription!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      // Cancel button
                      if (widget.status == AgentActivityStatus.running &&
                          widget.onCancel != null)
                        IconButton(
                          onPressed: widget.onCancel,
                          icon: Icon(
                            Icons.close,
                            color: AppColors.error,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      // Expand indicator
                      if (widget.steps.isNotEmpty)
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                    ],
                  ),
                  // Progress bar (when running)
                  if (widget.status == AgentActivityStatus.running &&
                      widget.progress > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                        minRowHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Expanded Steps
          if (widget.steps.isNotEmpty)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildStepsList(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Steps',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textLightSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _AgentStepItem(
              step: step,
              index: index,
              isLast: index == widget.steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _AgentStepItem extends StatelessWidget {
  final AgentStep step;
  final int index;
  final bool isLast;

  const _AgentStepItem({
    required this.step,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color stepColor;
    IconData stepIcon;

    switch (step.status) {
      case StepStatus.pending:
        stepColor = AppColors.textLightSecondary;
        stepIcon = Icons.circle_outlined;
        break;
      case StepStatus.running:
        stepColor = AppColors.warning;
        stepIcon = Icons.play_circle;
        break;
      case StepStatus.completed:
        stepColor = AppColors.success;
        stepIcon = Icons.check_circle;
        break;
      case StepStatus.error:
        stepColor = AppColors.error;
        stepIcon = Icons.error;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(
                  stepIcon,
                  color: stepColor,
                  size: 16,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: stepColor.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Step content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  if (step.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.description!,
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
          ),
        ],
      ),
    );
  }
}

/// Represents a single step in an agent's execution
class AgentStep {
  final String title;
  final String? description;
  final StepStatus status;
  final DateTime? timestamp;

  const AgentStep({
    required this.title,
    this.description,
    this.status = StepStatus.pending,
    this.timestamp,
  });
}

enum StepStatus { pending, running, completed, error }