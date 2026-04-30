import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

class ThinkingIndicator extends StatefulWidget {
  final String? message;
  final VoidCallback? onCancel;
  final bool compact;

  const ThinkingIndicator({
    super.key,
    this.message,
    this.onCancel,
    this.compact = false,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thinking',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildDots(size: 6),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Animated dots
          _buildDots(size: 8),
          const SizedBox(width: AppSpacing.md),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thinking...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Cancel button
          if (widget.onCancel != null)
            IconButton(
              onPressed: widget.onCancel,
              icon: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textLight.withOpacity(0.5),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots({required double size}) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_bounceAnimation.value + delay) % 1.0;
            final scale = _calculateDotScale(progress);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: size * 0.3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.6 + (scale - 0.5) * 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculateDotScale(double progress) {
    // Each dot bounces up and down with a sine wave
    // Using sine to get smooth up and down motion
    final sineValue = (progress * 2 * 3.14159);
    return 0.5 + (0.5 * (1 - (sineValue - 3.14159).abs() / 3.14159).clamp(0.0, 1.0));
  }
}