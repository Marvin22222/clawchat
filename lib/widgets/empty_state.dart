import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/spacing.dart';
import '../core/constants/typography.dart';
import 'package:iconsax/iconsax.dart';

class BetterEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;
  final BetterEmptyStateAnimationType animationType;

  const BetterEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.isDark,
    this.animationType = BetterEmptyStateAnimationType.pulse,
  });

  @override
  State<BetterEmptyState> createState() => _BetterEmptyStateState();
}

enum BetterEmptyStateAnimationType {
  pulse,
  bounce,
  fade,
}

class _BetterEmptyStateState extends State<BetterEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    if (widget.animationType == BetterEmptyStateAnimationType.pulse) {
      _controller.repeat(reverse: true);
    } else if (widget.animationType == BetterEmptyStateAnimationType.bounce) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getBounceOffset(double value) {
    // bounce between 0 and -10 pixels
    return -10 * value;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              _buildAnimatedIcon(),
              const SizedBox(height: AppSpacing.lg),
              // Title
              Text(
                widget.title,
                style: AppTypography.h4.copyWith(
                  color: widget.isDark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              // Subtitle
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: widget.isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              // Action button
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: widget.onAction,
                  icon: const Icon(Iconsax.refresh),
                  label: Text(widget.actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final iconColor = widget.isDark
        ? AppColors.textDarkSecondary.withValues(alpha: 0.4)
        : AppColors.textLightSecondary.withValues(alpha: 0.4);

    final iconContainerColor = AppColors.primary.withValues(alpha: 0.1);

    Widget iconWidget = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: iconContainerColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon,
        size: 48,
        color: AppColors.primary,
      ),
    );

    switch (widget.animationType) {
      case BetterEmptyStateAnimationType.pulse:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: iconWidget,
            );
          },
        );
      case BetterEmptyStateAnimationType.bounce:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _getBounceOffset(_controller.value)),
              child: iconWidget,
            );
          },
        );
      case BetterEmptyStateAnimationType.fade:
        return iconWidget;
    }
  }
}
