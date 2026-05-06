import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_status.dart';

/// Animated progress bar widget for agent tasks
class ProgressBar extends StatefulWidget {
  /// Progress value between 0.0 and 1.0
  final double progress;
  
  /// Height of the progress bar
  final double height;
  
  /// Whether to show percentage text in the center
  final bool showPercentage;
  
  /// Custom color override (uses status color by default)
  final Color? color;
  
  /// Background track color
  final Color? trackColor;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.showPercentage = true,
    this.color,
    this.trackColor,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = widget.color ?? _getDefaultColor(isDark);
    final backgroundColor = widget.trackColor ?? 
        (isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentProgress = _animation.value;
        
        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Track background
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
              
              // Progress fill
              FractionallySizedBox(
                widthFactor: currentProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Percentage text overlay
              if (widget.showPercentage)
                Center(
                  child: Text(
                    '${(currentProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      fontSize: widget.height * 0.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getDefaultColor(bool isDark) {
    // Default green color for progress bars
    return isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
  }
}