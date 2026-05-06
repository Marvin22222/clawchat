import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/agent_status.dart';

/// Filter and sort options for agent list
enum AgentFilter { all, active, idle, error }

enum AgentSort { name, status, lastActive }

enum AgentViewMode { grid, list }

/// Filter bar with filter/sort options and view mode toggle
class FilterBar extends StatelessWidget {
  final AgentFilter selectedFilter;
  final AgentSort selectedSort;
  final AgentViewMode viewMode;
  final ValueChanged<AgentFilter> onFilterChanged;
  final ValueChanged<AgentSort> onSortChanged;
  final ValueChanged<AgentViewMode> onViewModeChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.viewMode,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter == AgentFilter.all,
                  onTap: () => onFilterChanged(AgentFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: selectedFilter == AgentFilter.active,
                  color: const Color(0xFF22C55E),
                  onTap: () => onFilterChanged(AgentFilter.active),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Idle',
                  isSelected: selectedFilter == AgentFilter.idle,
                  color: const Color(0xFF6B7280),
                  onTap: () => onFilterChanged(AgentFilter.idle),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Error',
                  isSelected: selectedFilter == AgentFilter.error,
                  color: const Color(0xFFEF4444),
                  onTap: () => onFilterChanged(AgentFilter.error),
                ),
                const SizedBox(width: 16),
                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: isDark ? AppColors.border : AppColors.borderLight,
                ),
                const SizedBox(width: 16),
                // Sort dropdown
                _SortDropdown(
                  selectedSort: selectedSort,
                  onChanged: onSortChanged,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // View mode toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ViewModeToggle(
                viewMode: viewMode,
                onChanged: onViewModeChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : (isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.border : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final AgentSort selectedSort;
  final ValueChanged<AgentSort> onChanged;

  const _SortDropdown({
    required this.selectedSort,
    required this.onChanged,
  });

  String _getSortLabel(AgentSort sort) {
    switch (sort) {
      case AgentSort.name:
        return 'Name';
      case AgentSort.status:
        return 'Status';
      case AgentSort.lastActive:
        return 'Last Active';
    }
  }

  IconData _getSortIcon(AgentSort sort) {
    switch (sort) {
      case AgentSort.name:
        return Icons.sort_by_alpha;
      case AgentSort.status:
        return Icons.circle;
      case AgentSort.lastActive:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<AgentSort>(
      initialValue: selectedSort,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: isDark ? AppColors.bgElevated : AppColors.bgLightSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.border : AppColors.borderLight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSortIcon(selectedSort),
              size: 14,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Sort: ${_getSortLabel(selectedSort)}',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => AgentSort.values.map((sort) {
        return PopupMenuItem<AgentSort>(
          value: sort,
          child: Row(
            children: [
              Icon(
                _getSortIcon(sort),
                size: 16,
                color: sort == selectedSort
                    ? AppColors.primary
                    : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                _getSortLabel(sort),
                style: TextStyle(
                  color: sort == selectedSort
                      ? AppColors.primary
                      : (isDark ? AppColors.textDark : AppColors.textLight),
                  fontWeight: sort == selectedSort ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (sort == selectedSort) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final AgentViewMode viewMode;
  final ValueChanged<AgentViewMode> onChanged;

  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            icon: Icons.grid_view_rounded,
            isSelected: viewMode == AgentViewMode.grid,
            onTap: () => onChanged(AgentViewMode.grid),
            isFirst: true,
          ),
          _ViewModeButton(
            icon: Icons.view_list_rounded,
            isSelected: viewMode == AgentViewMode.list,
            onTap: () => onChanged(AgentViewMode.list),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: !isFirst ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
        ),
      ),
    );
  }
}