import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../chat/chat_screen.dart';

class QuickActionWidget extends StatelessWidget {
  const QuickActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Schnellaktionen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _QuickActionCard(
                icon: Iconsax.add_circle_outline,
                title: 'Neuer Chat',
                color: AppColors.primary,
                isDark: isDark,
                onTap: auth.ws.isConnected
                    ? () => Navigator.push(
                        context,
                        AppPageTransitions.fadeSlide(
                          builder: (_) => const ChatScreen(),
                        ),
                      )
                    : null,
              ),
              _QuickActionCard(
                icon: Iconsax.robot,
                title: 'Agents',
                color: AppColors.secondary,
                isDark: isDark,
                onTap: auth.ws.isConnected ? () {} : null,
              ),
              _QuickActionCard(
                icon: Iconsax.clock_1,
                title: 'Verlauf',
                color: AppColors.info,
                isDark: isDark,
                onTap: () {},
              ),
              _QuickActionCard(
                icon: Iconsax.task_alt,
                title: 'Tasks',
                color: AppColors.success,
                isDark: isDark,
                onTap: auth.ws.isConnected ? () {} : null,
              ),
              _QuickActionCard(
                icon: Iconsax.setting_2,
                title: 'Einstellungen',
                color: AppColors.warning,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionBanner extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onRetry;

  const ConnectionBanner({
    super.key,
    required this.isConnected,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isConnected ? 'Verbunden mit Gateway' : 'Nicht verbunden',
              style: TextStyle(
                fontSize: 13,
                color: isConnected ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          if (!isConnected && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
        ],
      ),
    );
  }
}

class AgentChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const AgentChip({
    super.key,
    required this.name,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.robot,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
