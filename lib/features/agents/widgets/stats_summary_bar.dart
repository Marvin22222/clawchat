import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_session.dart';

/// Horizontal stats bar showing agent count summary
class StatsSummaryBar extends StatelessWidget {
  /// List of agents to derive stats from
  final List<AgentSession> agents;
  
  /// Optional custom callback when tapped
  final VoidCallback? onTap;

  const StatsSummaryBar({
    super.key,
    required this.agents,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final totalAgents = agents.length;
    final activeCount = agents.where((a) => 
        a.status.name == 'live' || a.status.name == 'busy').length;
    final busyCount = agents.where((a) => a.status.name == 'busy').length;
    final errorCount = agents.where((a) => a.status.name == 'error').length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'Agents',
                value: '$totalAgents',
                icon: Iconsax.robot_outlined,
                color: AppColors.primary,
              ),
              _divider(isDark),
              _StatChip(
                label: 'Active',
                value: '$activeCount',
                icon: Iconsax.tick_square_circle_outline,
                color: const Color(0xFF22C55E),
              ),
              _divider(isDark),
              _StatChip(
                label: 'Busy',
                value: '$busyCount',
                icon: Iconsax.timer_pause_outlined,
                color: const Color(0xFFEAB308),
              ),
              _divider(isDark),
              _StatChip(
                label: 'Errors',
                value: '$errorCount',
                icon: Iconsax.warning_2_outline,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark ? AppColors.border : AppColors.borderLight,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}