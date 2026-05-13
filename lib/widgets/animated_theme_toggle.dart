import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated theme toggle with sun/moon icons and smooth transitions.
/// Provides a visually appealing way to switch between dark and light modes.
class AnimatedThemeToggle extends StatefulWidget {
  /// Current dark mode state
  final bool isDark;

  /// Callback when theme is toggled
  final VoidCallback onToggle;

  /// Size of the toggle button (default: 40)
  final double size;

  const AnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
    this.size = 40,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(widget.size / 3),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: (widget.isDark ? Colors.indigo : Colors.orange)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: widget.isDark
                    ? _buildMoonIcon(key: const ValueKey('moon'))
                    : _buildSunIcon(key: const ValueKey('sun')),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoonIcon({Key? key}) {
    return Container(
      key: key,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stars
          ...List.generate(3, (index) {
            final angle = (index * 120) * (math.pi / 180);
            final radius = widget.size * 0.35;
            return Positioned(
              left: widget.size / 2 +
                  radius * math.cos(angle) -
                  3,
              top: widget.size / 2 +
                  radius * math.sin(angle) -
                  3,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 100)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          // Moon
          Icon(
            Icons.nightlight_round,
            color: Colors.indigo.shade300,
            size: widget.size * 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildSunIcon({Key? key}) {
    return Container(
      key: key,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sun rays
          ...List.generate(8, (index) {
            final angle = (index * 45) * (math.pi / 180);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: Duration(milliseconds: 200 + (index * 20)),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: angle,
                  child: Transform.translate(
                    offset: Offset(0, -widget.size * 0.35 * value),
                    child: Container(
                      width: 2,
                      height: widget.size * 0.12,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.6 + (index * 0.05)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Sun center
          Container(
            width: widget.size * 0.35,
            height: widget.size * 0.35,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.shade300,
                  Colors.orange.shade400,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple animated theme toggle for compact spaces
/// Shows sun/moon icon with subtle animation
class CompactAnimatedThemeToggle extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const CompactAnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<CompactAnimatedThemeToggle> createState() =>
      _CompactAnimatedThemeToggleState();
}

class _CompactAnimatedThemeToggleState
    extends State<CompactAnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0.5).animate(
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
    return GestureDetector(
      onTap: () {
        if (widget.isDark) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
        widget.onToggle();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.indigo.withOpacity(0.15)
              : Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * math.pi,
              child: Icon(
                widget.isDark ? Icons.nightlight_round : Icons.wb_sunny,
                size: 18,
                color: widget.isDark ? Colors.indigo.shade300 : Colors.orange,
              ),
            );
          },
        ),
      ),
    );
  }
}