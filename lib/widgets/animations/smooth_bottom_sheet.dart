import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';

/// A smooth bottom sheet with snap points, haptic feedback, and scrim fade
/// Replaces standard DraggableScrollableSheet with iOS-like spring physics
class SmoothBottomSheet extends StatefulWidget {
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final List<double> snapSizes;
  final bool enableSnap;
  final Widget Function(BuildContext, ScrollController) builder;
  final ScrollController? scrollController;
  final Color? backgroundColor;
  final double borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableDrag;
  final bool dismissOnScrimClick;
  final VoidCallback? onDismissed;

  const SmoothBottomSheet({
    super.key,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    this.snapSizes = const [0.5, 0.9, 1.0],
    this.enableSnap = true,
    required this.builder,
    this.scrollController,
    this.backgroundColor,
    this.borderRadius = 20.0,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeOutCubic,
    this.enableDrag = true,
    this.dismissOnScrimClick = true,
    this.onDismissed,
  });

  /// Quick factory for standard settings-style sheets
  factory SmoothBottomSheet.settings({
    Key? key,
    required Widget Function(BuildContext, ScrollController) builder,
    ScrollController? scrollController,
    double initialChildSize = 0.7,
    double maxChildSize = 0.9,
    double minChildSize = 0.5,
    Color? backgroundColor,
    VoidCallback? onDismissed,
  }) {
    return SmoothBottomSheet(
      key: key,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snapSizes: const [0.5, 0.7, 0.9],
      builder: builder,
      scrollController: scrollController,
      backgroundColor: backgroundColor,
      onDismissed: onDismissed,
    );
  }

  /// Quick factory for modal sheets with full height option
  factory SmoothBottomSheet.modal({
    Key? key,
    required Widget Function(BuildContext, ScrollController) builder,
    ScrollController? scrollController,
    double initialChildSize = 0.6,
    Color? backgroundColor,
    VoidCallback? onDismissed,
  }) {
    return SmoothBottomSheet(
      key: key,
      initialChildSize: initialChildSize,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      snapSizes: const [0.4, 0.6, 1.0],
      builder: builder,
      scrollController: scrollController,
      backgroundColor: backgroundColor,
      borderRadius: 20.0,
      onDismissed: onDismissed,
    );
  }

  @override
  State<SmoothBottomSheet> createState() => _SmoothBottomSheetState();
}

class _SmoothBottomSheetState extends State<SmoothBottomSheet>
    with SingleTickerProviderStateMixin {
  late DraggableScrollableController _controller;
  late AnimationController _scrimController;
  late Animation<double> _scrimAnimation;
  double _currentSize = 0;
  bool _isDragging = false;
  bool _isAnimating = false;
  double? _lastSnapSize;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _scrimController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: 1.0,
    );
    _scrimAnimation = CurvedAnimation(
      parent: _scrimController,
      curve: Curves.easeOut,
    );
    _currentSize = widget.initialChildSize;
    _lastSnapSize = widget.initialChildSize;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrimController.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    _isDragging = true;
    _lastSnapSize = _currentSize;
    HapticFeedback.selectionClick();
  }

  void _handleDragUpdate(double delta, double extent) {
    // Calculate current size from extent
    final newSize = _currentSize + delta;
    setState(() => _currentSize = newSize.clamp(widget.minChildSize, widget.maxChildSize));
  }

  void _handleDragEnd(double velocity, double extent) {
    _isDragging = false;
    
    if (widget.enableSnap && widget.snapSizes.isNotEmpty) {
      final targetSize = _findClosestSnapSize(_currentSize, velocity);
      
      if (targetSize != _lastSnapSize) {
        // Snap to new size with haptic feedback
        HapticFeedback.mediumImpact();
        _lastSnapSize = targetSize;
      }
      
      _isAnimating = true;
      _controller.animateTo(
        targetSize,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      ).then((_) {
        _isAnimating = false;
        setState(() => _currentSize = targetSize);
        
        // If dismissed (snap to min and close), trigger callback
        if (targetSize <= widget.minChildSize && widget.onDismissed != null) {
          widget.onDismissed!();
        }
      });
    }
  }

  double _findClosestSnapSize(double currentSize, double velocity) {
    if (widget.snapSizes.isEmpty) return currentSize;
    
    // If velocity is significant, decide based on direction
    if (velocity.abs() > 500) {
      if (velocity > 0) {
        // Dragging up - find next larger snap point
        for (final snap in widget.snapSizes) {
          if (snap > currentSize) return snap;
        }
        return widget.snapSizes.last;
      } else {
        // Dragging down - find next smaller snap point
        final reversed = widget.snapSizes.reversed.toList();
        for (final snap in reversed) {
          if (snap < currentSize) return snap;
        }
        return widget.snapSizes.first;
      }
    }
    
    // No significant velocity - snap to closest
    double closest = widget.snapSizes.first;
    double minDiff = (_currentSize - closest).abs();
    
    for (final snap in widget.snapSizes) {
      final diff = (_currentSize - snap).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = snap;
      }
    }
    
    return closest;
  }

  void _handleSizeChanged(double previousSize, double currentSize, bool isAnimating) {
    if (!mounted) return;
    
    // Update scrim opacity based on sheet position
    final progress = (currentSize - widget.minChildSize) / 
                    (widget.maxChildSize - widget.minChildSize);
    _scrimController.value = 1.0 - progress.clamp(0.0, 1.0);
    
    if (isAnimating && !_isDragging) {
      setState(() => _currentSize = currentSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? 
        (isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary);

    return Stack(
      children: [
        // Scrim background with fade
        AnimatedBuilder(
          animation: _scrimAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: widget.dismissOnScrimClick
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    }
                  : null,
              child: Container(
                color: Colors.black.withOpacity(0.4 * _scrimAnimation.value),
              ),
            );
          },
        ),
        
        // DraggableScrollableSheet with snap points
        DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: widget.initialChildSize,
          minChildSize: widget.minChildSize,
          maxChildSize: widget.maxChildSize,
          snap: widget.enableSnap,
          snapSizes: widget.snapSizes,
          builder: (context, scrollController) {
            return _SheetContent(
              scrollController: scrollController,
              enableDrag: widget.enableDrag,
              borderRadius: widget.borderRadius,
              onDragStart: _handleDragStart,
              onDragUpdate: _handleDragUpdate,
              onDragEnd: _handleDragEnd,
              onSizeChanged: _handleSizeChanged,
              builder: widget.builder,
              backgroundColor: bgColor,
            );
          },
        ),
      ],
    );
  }
}

class _SheetContent extends StatefulWidget {
  final ScrollController scrollController;
  final bool enableDrag;
  final double borderRadius;
  final VoidCallback onDragStart;
  final Function(double, double) onDragUpdate;
  final Function(double, double) onDragEnd;
  final Function(double, double, bool) onSizeChanged;
  final Widget Function(BuildContext, ScrollController) builder;
  final Color backgroundColor;

  const _SheetContent({
    required this.scrollController,
    required this.enableDrag,
    required this.borderRadius,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onSizeChanged,
    required this.builder,
    required this.backgroundColor,
  });

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  double _previousExtent = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          widget.onDragStart();
        } else if (notification is ScrollUpdateNotification) {
          // Handle scroll updates for drag
        } else if (notification is ScrollEndNotification) {
          // Handle drag end
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar with drag gesture
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => widget.onDragStart(),
              onVerticalDragUpdate: (details) {
                final delta = details.primaryDelta! / 
                            MediaQuery.of(context).size.height;
                widget.onDragUpdate(delta, _previousExtent);
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                widget.onDragEnd(velocity, _previousExtent);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: widget.builder(context, widget.scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show a smooth bottom sheet modal
Future<T?> showSmoothBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.95,
  List<double> snapSizes = const [0.5, 0.9, 1.0],
  bool enableSnap = true,
  Color? backgroundColor,
  double borderRadius = 20.0,
  Duration animationDuration = const Duration(milliseconds: 250),
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    builder: (context) => SmoothBottomSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snapSizes: snapSizes,
      enableSnap: enableSnap,
      builder: builder,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      animationDuration: animationDuration,
      dismissOnScrimClick: isDismissible,
      enableDrag: enableDrag,
    ),
  );
}

/// Quick settings-style sheet with preset values for ClawChat
Future<T?> showSettingsSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  ScrollController? scrollController,
  double initialChildSize = 0.7,
  double maxChildSize = 0.9,
  double minChildSize = 0.5,
}) {
  return showSmoothBottomSheet<T>(
    context: context,
    initialChildSize: initialChildSize,
    minChildSize: minChildSize,
    maxChildSize: maxChildSize,
    snapSizes: const [0.5, 0.7, 0.9],
    builder: builder,
  );
}
