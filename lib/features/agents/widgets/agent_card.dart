import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../models/agent_session.dart';
import '../../models/agent_status.dart';
import 'status_indicator.dart';

/// Card widget displaying agent status, name, and current task
/// with animations based on agent status
class AgentCard extends StatefulWidget {
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
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Shake animation for ERROR
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    // Glow animation for LIVE
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _startAnimations();
  }

  void _startAnimations() {
    if (widget.agent.status == AgentStatus.error) {
      _shakeController.repeat(reverse: true);
    } else if (widget.agent.status == AgentStatus.live) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AgentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.status != widget.agent.status) {
      _shakeController.stop();
      _glowController.stop();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLive = widget.agent.status == AgentStatus.live;
    final isError = widget.agent.status == AgentStatus.error;

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _glowController]),
      builder: (context, child) {
        return Transform.translate(
          offset: isError ? Offset(_shakeAnimation.value, 0) : Offset.zero,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.border : AppColors.borderLight,
                width: 1,
              ),
              // Pulsing glow for LIVE status
              boxShadow: isLive
                  ? [
                      BoxShadow(
                        color: Color(isDark 
                            ? widget.agent.status.darkColor 
                            : widget.agent.status.lightColor)
                            .withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 12 + (8 * _glowAnimation.value),
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
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
                        widget.agent.avatarEmoji,
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
                          widget.agent.name,
                          style: TextStyle(
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.agent.role != null)
                          Text(
                            widget.agent.role!,
                            style: TextStyle(
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  StatusIndicator(status: widget.agent.status, size: 20),
                ],
              ),

              const SizedBox(height: 12),

              // Current task
              if (widget.agent.currentTask != null)
                Text(
                  widget.agent.currentTask!,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Progress bar
              if (widget.agent.status == AgentStatus.busy || widget.agent.progress > 0)
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
                          '${(widget.agent.progress * 100).toInt()}%',
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
                        value: widget.agent.progress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? AppColors.bgDarkTertiary
                            : AppColors.bgLightTertiary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(widget.agent.status, isDark),
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
                  if (widget.agent.steps.isNotEmpty)
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
                          '${widget.agent.steps.length} steps',
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
                  if (widget.agent.startedAt != null)
                    Text(
                      widget.agent.durationString,
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
