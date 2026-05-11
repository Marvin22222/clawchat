import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

/// "Agent schreibt..." indicator shown below the last assistant message
/// during streaming. Shows animated bouncing dots with "schreibt..." text.
class AgentTypingIndicator extends StatefulWidget {
  /// The name of the agent that is typing
  final String? agentName;

  const AgentTypingIndicator({
    super.key,
    this.agentName,
  });

  @override
  State<AgentTypingIndicator> createState() => _AgentTypingIndicatorState();
}

class _AgentTypingIndicatorState extends State<AgentTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar placeholder
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Center(
              child: Text(
                (widget.agentName ?? 'A')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Typing indicator bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.assistantBubbleDark 
                  : AppColors.assistantBubbleLight,
              borderRadius: BorderRadius.circular(AppRadius.large).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated bouncing dots
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      // Staggered animation: dot 0 at 0ms, dot 1 at 200ms, dot 2 at 400ms
                      final delay = index * 0.167; // ~200ms at 1200ms duration
                      final progress = (_bounceAnimation.value + delay) % 1.0;
                      
                      // Bounce up and down
                      final bounce = _calculateBounce(progress);
                      
                      return Transform.translate(
                        offset: Offset(0, -bounce * 4),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.4 + (bounce * 0.6)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(width: AppSpacing.sm),
                
                // "schreibt..." text
                Text(
                  'schreibt',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark 
                        ? AppColors.textDarkSecondary 
                        : AppColors.textLightSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBounce(double progress) {
    // Smooth bounce: 0 -> 1 -> 0 over the progress
    // Using sine curve for smooth up and down
    if (progress < 0.5) {
      // Going up
      return progress * 2;
    } else {
      // Coming down
      return (1 - progress) * 2;
    }
  }
}

/// Animated bouncing dots for typing indicator
class BouncingDots extends StatefulWidget {
  final double dotSize;
  final Color color;
  final int dotCount;
  final Duration duration;
  final double spacing;

  const BouncingDots({
    super.key,
    this.dotSize = 6,
    this.color = AppColors.primary,
    this.dotCount = 3,
    this.duration = const Duration(milliseconds: 1200),
    this.spacing = 4,
  });

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.dotCount, (index) {
            // Staggered delay
            final delay = index * 0.167; // ~200ms stagger
            final progress = (_controller.value + delay) % 1.0;
            
            // Bounce calculation with opacity
            final bounce = _calculateBounce(progress);
            final opacity = 0.3 + (bounce * 0.7);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, -bounce * 4),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculateBounce(double progress) {
    if (progress < 0.5) {
      return progress * 2;
    } else {
      return (1 - progress) * 2;
    }
  }
}