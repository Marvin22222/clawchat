import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../models/message.dart';

/// Animation configuration for chat message appear animations
class AnimationConfig {
  static const Duration messageAppearDuration = Duration(milliseconds: 300);
  static const Curve messageAppearCurve = Curves.easeOutCubic;
  static const double slideUpOffset = 20.0; // pixels
}

/// Wrapper widget that applies appear animation to message bubbles
/// Uses Fade + Slide up effect (20px from bottom)
/// Respects reduce motion settings for accessibility
class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;
  final Curve curve;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Check for reduce motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // 20% of height
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate && !reduceMotion) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // Already visible, skip animation
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    // If reduce motion is enabled, just show the child without animation
    if (reduceMotion) {
      return widget.child;
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A widget that wraps content with a smooth appear animation
/// Uses AnimatedSwitcher for seamless transitions
class MessageAppearWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const MessageAppearWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Staggered animation for lists of items
class StaggeredAnimationBuilder extends StatelessWidget {
  final int index;
  final int totalItems;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerDuration;

  const StaggeredAnimationBuilder({
    super.key,
    required this.index,
    required this.totalItems,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
    this.staggerDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(
      milliseconds: baseDelay.inMilliseconds + (index * staggerDuration.inMilliseconds),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}
