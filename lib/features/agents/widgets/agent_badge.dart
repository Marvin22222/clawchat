import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_status.dart';

/// Notification badge overlay for agent tab showing active/error counts
class AgentBadge extends StatelessWidget {
  /// Number to display (typically active agent count)
  final int count;
  
  /// Whether to show error state (red badge)
  final bool hasError;
  
  /// Size of the badge
  final double size;

  const AgentBadge({
    super.key,
    required this.count,
    this.hasError = false,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !hasError) {
      return const SizedBox.shrink();
    }

    final color = hasError ? AppColors.error : AppColors.primary;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayCount,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Animated badge that pulses when there are active agents
class AnimatedAgentBadge extends StatefulWidget {
  final int count;
  final bool hasError;
  final double size;

  const AnimatedAgentBadge({
    super.key,
    required this.count,
    this.hasError = false,
    this.size = 18,
  });

  @override
  State<AnimatedAgentBadge> createState() => _AnimatedAgentBadgeState();
}

class _AnimatedAgentBadgeState extends State<AnimatedAgentBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.count > 0 || widget.hasError) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedAgentBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 || widget.hasError) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: (widget.count > 0 || widget.hasError) ? _animation.value : 1.0,
          child: AgentBadge(
            count: widget.count,
            hasError: widget.hasError,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Card-level notification indicator (pulsing dot for active, shake for error)
class AgentStatusBadge extends StatelessWidget {
  final AgentStatus status;
  final double size;

  const AgentStatusBadge({
    super.key,
    required this.status,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(status.darkColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}