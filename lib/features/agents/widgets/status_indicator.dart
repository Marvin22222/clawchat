import 'package:flutter/material.dart';
import '../../../models/agent_status.dart';

/// Widget showing agent status indicator with animations
/// - LIVE: Slow pulse (2s), green dot
/// - BUSY: Spinning ring (1s), yellow
/// - IDLE: Static gray circle
/// - ERROR: Shake animation (3x, 200ms), red
class StatusIndicator extends StatefulWidget {
  final AgentStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _spinController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for LIVE
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Shake animation for ERROR
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    // Spin animation for BUSY
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _startAnimation();
  }

  void _startAnimation() {
    switch (widget.status) {
      case AgentStatus.live:
        _pulseController.repeat(reverse: true);
        break;
      case AgentStatus.busy:
        _spinController.repeat();
        break;
      case AgentStatus.error:
        _shakeController.repeat(reverse: true);
        break;
      case AgentStatus.idle:
        // No animation for IDLE - static
        break;
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      // Stop all animations
      _pulseController.stop();
      _shakeController.stop();
      _spinController.stop();
      // Start new animation
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(isDark ? widget.status.darkColor : widget.status.lightColor);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shakeController, _spinController]),
      builder: (context, child) {
        return Transform.translate(
          offset: widget.status == AgentStatus.error
              ? Offset(_shakeAnimation.value, 0)
              : Offset.zero,
          child: Opacity(
            opacity: widget.status == AgentStatus.live ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIndicator(color),
                  const SizedBox(width: 6),
                  Text(
                    widget.status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator(Color color) {
    final size = widget.size;
    
    switch (widget.status) {
      case AgentStatus.live:
        // Pulsing dot
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      
      case AgentStatus.busy:
        // Spinning ring
        return SizedBox(
          width: size,
          height: size,
          child: Transform.rotate(
            angle: _spinController.value * 2 * 3.14159,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        );
      
      case AgentStatus.idle:
        // Static gray circle
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        );
      
      case AgentStatus.error:
        // Static red circle with X
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.close,
              size: size * 0.7,
              color: Colors.white,
            ),
          ),
        );
    }
  }
}
