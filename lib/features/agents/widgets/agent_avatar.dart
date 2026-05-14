import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_status.dart';

/// Avatar widget for agents with role-based icon
class AgentAvatar extends StatelessWidget {
  /// Agent role for icon selection
  final String? role;
  
  /// Avatar size variant
  final AgentAvatarSize size;
  
  /// Override the default emoji icon
  final String? icon;
  
  /// Optional status for additional visual feedback
  final AgentStatus? status;

  const AgentAvatar({
    super.key,
    this.role,
    this.size = AgentAvatarSize.md,
    this.icon,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.pixelSize,
      height: size.pixelSize,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(size.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          icon ?? _getIconForRole(),
          style: TextStyle(
            fontSize: size.iconSize,
          ),
        ),
      ),
    );
  }

  String _getIconForRole() {
    if (icon != null) return icon!;
    if (role == null) return '🎭';
    
    switch (role!.toLowerCase()) {
      case 'main':
        return '🤖';
      case 'coding':
      case 'cody':
        return '👾';
      case 'research':
      case 'deep':
        return '🔍';
      case 'autotask':
      case 'auto':
        return '⚡';
      default:
        return '🎭';
    }
  }
}

/// Size variants for AgentAvatar
enum AgentAvatarSize {
  sm,
  md,
  lg,
  xl;

  double get pixelSize {
    switch (this) {
      case AgentAvatarSize.xl:
        return 80;
      case AgentAvatarSize.sm:
        return 32;
      case AgentAvatarSize.md:
        return 48;
      case AgentAvatarSize.lg:
        return 64;
    }
  }

  double get iconSize {
    switch (this) {
      case AgentAvatarSize.sm:
        return 16;
      case AgentAvatarSize.md:
        return 24;
      case AgentAvatarSize.lg:
        return 32;
      case AgentAvatarSize.xl:
        return 40;
    }
  }

  double get borderRadius {
    switch (this) {
      case AgentAvatarSize.sm:
        return 8;
      case AgentAvatarSize.md:
        return 12;
      case AgentAvatarSize.lg:
        return 16;
      case AgentAvatarSize.xl:
        return 20;
    }
  }
}