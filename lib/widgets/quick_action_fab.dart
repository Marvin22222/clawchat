import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.color,
  });
}

class QuickActionFab extends StatefulWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onVoiceMessage;
  final VoidCallback? onCamera;
  final VoidCallback? onSettings;

  const QuickActionFab({
    super.key,
    this.onNewChat,
    this.onVoiceMessage,
    this.onCamera,
    this.onSettings,
  });

  @override
  State<QuickActionFab> createState() => _QuickActionFabState();
}

class _QuickActionFabState extends State<QuickActionFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

  final List<QuickAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _expand() {
    HapticService.mediumImpact();
    setState(() => _isExpanded = true);
    _controller.forward();
    _showOverlay();
  }

  void _collapse() {
    HapticService.lightImpact();
    setState(() => _isExpanded = false);
    _controller.reverse();
    _removeOverlay();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _RadialMenuOverlay(
        actions: _buildActions(),
        scaleAnimation: _scaleAnimation,
        rotationAnimation: _rotationAnimation,
        onDismiss: _collapse,
        fabKey: _fabKey,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<QuickAction> _buildActions() {
    return [
      QuickAction(
        icon: Iconsax.add,
        label: 'Neuer Chat',
        tooltip: 'Neuen Chat starten',
        onTap: () {
          _collapse();
          widget.onNewChat?.call();
        },
      ),
      QuickAction(
        icon: Iconsax.microphone,
        label: 'Sprachnachricht',
        tooltip: 'Voice Message aufnehmen',
        onTap: () {
          _collapse();
          widget.onVoiceMessage?.call();
        },
        color: AppColors.error,
      ),
      QuickAction(
        icon: Iconsax.camera,
        label: 'Kamera',
        tooltip: 'Foto aufnehmen',
        onTap: () {
          _collapse();
          widget.onCamera?.call();
        },
        color: AppColors.warning,
      ),
      QuickAction(
        icon: Iconsax.setting_2,
        label: 'Einstellungen',
        tooltip: 'Einstellungen öffnen',
        onTap: () {
          _collapse();
          widget.onSettings?.call();
        },
        color: AppColors.info,
      ),
    ];
  }

  final GlobalKey _fabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      key: _fabKey,
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: AppColors.primary,
              elevation: 8,
              child: Icon(
                _isExpanded ? Iconsax.close : Iconsax.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadialMenuOverlay extends StatefulWidget {
  final List<QuickAction> actions;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final VoidCallback onDismiss;
  final GlobalKey fabKey;

  const _RadialMenuOverlay({
    required this.actions,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.onDismiss,
    required this.fabKey,
  });

  @override
  State<_RadialMenuOverlay> createState() => _RadialMenuOverlayState();
}

class _RadialMenuOverlayState extends State<_RadialMenuOverlay> {
  @override
  void initState() {
    super.initState();
    // Add tap detector to dismiss when tapping outside
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        // Listen for taps anywhere to dismiss
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Get FAB position
    final fabBox = widget.fabKey.currentContext?.findRenderObject() as RenderBox?;
    Offset fabPosition = Offset(screenSize.width - 80, screenSize.height - 160);

    if (fabBox != null) {
      final fabOffset = fabBox.localToGlobal(Offset.zero);
      fabPosition = Offset(fabOffset.dx + fabBox.size.width / 2, fabOffset.dy + fabBox.size.height / 2);
    }

    // Calculate menu positioning
    const menuRadius = 100.0;
    const fabSize = 56.0;
    const bottomMargin = 140.0; // Above input bar

    // Arc menu items in a fan pattern
    const startAngle = -math.pi * 0.75; // Start from upper left
    const sweepAngle = math.pi * 1.5; // Sweep 270 degrees

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            // Menu items
            ...List.generate(widget.actions.length, (index) {
              final action = widget.actions[index];
              // Distribute items in arc
              final angleStep = sweepAngle / (widget.actions.length - 1);
              final angle = startAngle + (angleStep * index);

              // Calculate position
              final x = fabPosition.dx + menuRadius * math.cos(angle) - 24;
              final y = fabPosition.dy + menuRadius * math.sin(angle) - 24;

              // Stagger animation
              final staggerDelay = index * 0.05;
              final delayedScale = CurvedAnimation(
                parent: ReverseAnimation(widget.scaleAnimation),
                curve: Interval(
                  staggerDelay,
                  0.6 + staggerDelay,
                  curve: Curves.easeOutBack,
                ),
              );

              return Positioned(
                left: x,
                top: y,
                child: AnimatedBuilder(
                  animation: delayedScale,
                  builder: (context, child) {
                    final scale = delayedScale.value;
                    if (scale == 0) return const SizedBox.shrink();

                    return Transform.scale(
                      scale: scale,
                      child: _RadialMenuItem(
                        action: action,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RadialMenuItem extends StatelessWidget {
  final QuickAction action;
  final bool isDark;

  const _RadialMenuItem({
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        action.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: action.color ?? AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (action.color ?? AppColors.primary).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.bgDarkSecondary.withOpacity(0.95)
                  : AppColors.bgLightSecondary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}