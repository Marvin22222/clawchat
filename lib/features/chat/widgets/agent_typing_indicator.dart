import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

/// "Agent tippt..." indicator shown during streaming.
/// Features smooth bouncing dots animation with bubble styling.
class AgentTypingIndicator extends StatefulWidget {
  /// The name of the agent that is typing
  final String? agentName;
  
  /// Custom text to display (default: "tippt...")
  final String? statusText;

  const AgentTypingIndicator({
    super.key,
    this.agentName,
    this.statusText,
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
      duration: const Duration(milliseconds: 600), // Faster, snappier
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
    final agentInitial = (widget.agentName ?? 'Agent')[0].toUpperCase();
    final statusText = widget.statusText ?? 'tippt';
    
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar
          Container(
            width: 32,
            height: 32,
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
                agentInitial,
                style: const TextStyle(
                  fontSize: 14,
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
              horizontal: AppSpacing.md + 4,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.assistantBubbleDark 
                  : AppColors.assistantBubbleLight,
              borderRadius: BorderRadius.circular(AppRadius.large).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated bouncing dots (larger: 10px)
                _BouncingDots(
                  dotSize: 10,
                  color: AppColors.primary,
                  spacing: 5,
                  animation: _bounceAnimation,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                
                // Status text
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark 
                        ? AppColors.textDarkSecondary 
                        : AppColors.textLightSecondary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated bouncing dots with smooth wave animation
class _BouncingDots extends StatelessWidget {
  final double dotSize;
  final Color color;
  final double spacing;
  final Animation<double> animation;

  const _BouncingDots({
    required this.dotSize,
    required this.color,
    required this.spacing,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Staggered animation: each dot starts 150ms behind the previous
            final delay = index * 0.25; // 25% offset per dot (600ms * 0.25 = 150ms)
            final progress = (animation.value + delay) % 1.0;
            
            // Smooth bounce calculation using sine wave
            final bounce = _smoothBounce(progress);
            final translateY = -bounce * 6; // Move up by 6px max
            
            // Opacity pulse: dots get brighter at the top of the bounce
            final opacity = 0.5 + (bounce * 0.5);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7 + (bounce * 0.3)),
                      shape: BoxShape.circle,
                      boxShadow: bounce > 0.5 
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
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

  /// Smooth sine-based bounce: 0 -> 1 -> 0 over full cycle
  double _smoothBounce(double progress) {
    // Use half sine wave for smooth up and down
    // progress 0.0 -> 0.5: goes up (0 -> 1)
    // progress 0.5 -> 1.0: comes down (1 -> 0)
    return (1 - (2 * progress - 1).abs());
  }
}

/// Standalone bouncing dots widget for reuse
class BouncingDots extends StatefulWidget {
  final double dotSize;
  final Color color;
  final int dotCount;
  final Duration duration;
  final double spacing;

  const BouncingDots({
    super.key,
    this.dotSize = 8,
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
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.dotCount, (index) {
            final delay = index * 0.25;
            final progress = (_animation.value + delay) % 1.0;
            final bounce = (1 - (2 * progress - 1).abs());
            final translateY = -bounce * 5;
            final opacity = 0.5 + (bounce * 0.5);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.5 + (bounce * 0.5)),
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
}