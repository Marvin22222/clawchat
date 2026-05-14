import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/typography.dart';

/// Loading skeleton with shimmer effect for realistic content placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool animate;
  final bool useShimmer;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.small,
    this.animate = true,
    this.useShimmer = true,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.animate) {
      _controller.repeat();
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
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    if (!widget.animate || !widget.useShimmer) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: baseColor,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Message bubble skeleton for chat loading
class MessageBubbleSkeleton extends StatelessWidget {
  final bool isUser;

  const MessageBubbleSkeleton({
    super.key,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar placeholder
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.medium),
                  topRight: const Radius.circular(AppRadius.medium),
                  bottomLeft: isUser
                      ? const Radius.circular(AppRadius.medium)
                      : const Radius.circular(AppRadius.small),
                  bottomRight: isUser
                      ? const Radius.circular(AppRadius.small)
                      : const Radius.circular(AppRadius.medium),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content lines
                  SkeletonLoader(
                    height: 14,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader(
                    height: 14,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader(
                    height: 14,
                    width: 100,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Timestamp
                  SkeletonLoader(
                    height: 10,
                    width: 60,
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            // Avatar placeholder
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chat loading state with multiple message skeletons
class ChatLoadingSkeleton extends StatelessWidget {
  final int messageCount;

  const ChatLoadingSkeleton({
    super.key,
    this.messageCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messageCount,
      itemBuilder: (context, index) {
        // Alternate between user and assistant messages
        return MessageBubbleSkeleton(
          isUser: index % 2 == 1,
        );
      },
    );
  }
}

/// Tool execution card skeleton
class ToolExecutionCardSkeleton extends StatelessWidget {
  const ToolExecutionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Tool icon placeholder
          SkeletonLoader(
            height: 40,
            width: 40,
            borderRadius: AppRadius.small,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tool name
                SkeletonLoader(
                  height: 16,
                  width: 120,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Status
                SkeletonLoader(
                  height: 12,
                  width: 60,
                ),
              ],
            ),
          ),
          // Expand icon
          const SkeletonLoader(
            height: 20,
            width: 20,
            borderRadius: 10,
          ),
        ],
      ),
    );
  }
}

/// Agent activity card skeleton
class AgentActivityCardSkeleton extends StatelessWidget {
  const AgentActivityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              SkeletonLoader(
                height: 24,
                width: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: AppSpacing.sm),
              const SkeletonLoader(
                height: 16,
                width: 80,
              ),
              const Spacer(),
              SkeletonLoader(
                height: 20,
                width: 60,
                borderRadius: AppRadius.full,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          SkeletonLoader(
            height: 6,
            borderRadius: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          // Step indicators
          Row(
            children: List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SkeletonLoader(
                height: 8,
                width: 8,
                borderRadius: 4,
              ),
            )),
          ),
        ],
      ),
    );
  }
}

/// Chat list item skeleton for conversation list
class ChatListItemSkeleton extends StatelessWidget {
  const ChatListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                SkeletonLoader(
                  height: 16,
                  width: 140,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Last message preview
                SkeletonLoader(
                  height: 12,
                  width: double.infinity,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Time + unread badge column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLoader(
                height: 10,
                width: 40,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Unread badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chat list skeleton with multiple items
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ChatListItemSkeleton(),
    );
  }
}

/// Task list item skeleton
class TaskListItemSkeleton extends StatelessWidget {
  const TaskListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Status icon container
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task name
                SkeletonLoader(
                  height: 16,
                  width: double.infinity,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Agent + status
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chevron
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tasks list skeleton
class TasksListSkeleton extends StatelessWidget {
  final int itemCount;


  const TasksListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const TaskListItemSkeleton(),
    );
  }
}

/// File list item skeleton
class FileListItemSkeleton extends StatelessWidget {
  const FileListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // File icon container
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name
                SkeletonLoader(
                  height: 14,
                  width: double.infinity,
                ),
                const SizedBox(height: AppSpacing.xs),
                // File size + date
                SkeletonLoader(
                  height: 10,
                  width: 100,
                ),
              ],
            ),
          ),
          // Menu icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Files list skeleton
class FilesListSkeleton extends StatelessWidget {
  final int itemCount;

  const FilesListSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const FileListItemSkeleton(),
    );
  }
}

/// Settings list tile skeleton
class SettingsListTileSkeleton extends StatelessWidget {
  final bool hasSubtitle;
  final bool hasTrailing;

  const SettingsListTileSkeleton({
    super.key,
    this.hasSubtitle = true,
    this.hasTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                SkeletonLoader(
                  height: 14,
                  width: 120,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SkeletonLoader(
                    height: 10,
                    width: 180,
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Settings section skeleton
class SettingsSectionSkeleton extends StatelessWidget {
  final int itemCount;

  const SettingsSectionSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: SkeletonLoader(
            height: 12,
            width: 80,
          ),
        ),
        // List tiles
        ...List.generate(itemCount, (_) => const SettingsListTileSkeleton()),
      ],
    );
  }
}

/// Full settings screen skeleton
class SettingsScreenSkeleton extends StatelessWidget {
  const SettingsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // App bar placeholder
        Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Center(
            child: SkeletonLoader(
              height: 20,
              width: 120,
            ),
          ),
        ),
        // Connection section
        const SettingsSectionSkeleton(itemCount: 2),
        // Presets section
        const SettingsSectionSkeleton(itemCount: 3),
        // General section
        const SettingsSectionSkeleton(itemCount: 4),
        // About section
        const SettingsSectionSkeleton(itemCount: 2),
      ],
    );
  }
}

/// Offline mode banner widget with slide-down animation
class OfflineBanner extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.onRetry,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: AppColors.warning.withOpacity(0.15),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Keine Verbindung',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onRetry != null)
                TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Iconsax.refresh, size: 14),
                  label: const Text('Erneut'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: const Size(0, 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Agent card skeleton for agents screen loading state
class AgentCardSkeleton extends StatelessWidget {
  const AgentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Agent icon placeholder
            SkeletonLoader(
              height: 56,
              width: 56,
              borderRadius: AppRadius.medium,
            ),
            const SizedBox(width: AppSpacing.md),
            // Agent info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    height: 16,
                    width: 120,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader(
                    height: 13,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Action icons
            Column(
              children: [
                SkeletonLoader(
                  height: 24,
                  width: 24,
                  borderRadius: 12,
                ),
                const SizedBox(height: AppSpacing.sm),
                SkeletonLoader(
                  height: 16,
                  width: 16,
                  borderRadius: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Agents list skeleton with multiple agent cards
class AgentsListSkeleton extends StatelessWidget {
  final int itemCount;

  const AgentsListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      itemBuilder: (context, index) => const AgentCardSkeleton(),
    );
  }
}

/// Home screen skeleton with quick action cards and agent list
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  height: 10,
                  width: 10,
                  borderRadius: 5,
                ),
                const SizedBox(width: AppSpacing.sm),
                SkeletonLoader(
                  height: 14,
                  width: 80,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Quick actions header
          SkeletonLoader(
            height: 20,
            width: 100,
          ),
          const SizedBox(height: AppSpacing.md),
          // Quick action cards
          Row(
            children: List.generate(3, (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? AppSpacing.md : 0),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Column(
                  children: [
                    SkeletonLoader(
                      height: 32,
                      width: 32,
                      borderRadius: AppRadius.small,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonLoader(
                      height: 12,
                      width: 50,
                    ),
                  ],
                ),
              ),
            )),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Agents header
          SkeletonLoader(
            height: 20,
            width: 120,
          ),
          const SizedBox(height: AppSpacing.md),
          // Agent list items
          ...List.generate(4, (index) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  height: 40,
                  width: 40,
                  borderRadius: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SkeletonLoader(
                    height: 14,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// BlurPlaceholder for image loading states
class BlurPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool showShimmer;

  const BlurPlaceholder({
    super.key,
    this.width = 100,
    this.height = 100,
    this.borderRadius = AppRadius.medium,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: height,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[300],
        ),
        child: Stack(
          children: [
            // Shimmer overlay
            if (showShimmer)
              _ShimmerOverlay(
                width: width,
                height: height,
                isDark: isDark,
              ),
            // Center icon
            Center(
              child: Icon(
                Icons.image_outlined,
                size: 32,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerOverlay extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;

  const _ShimmerOverlay({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = widget.isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.transparent,
                highlightColor.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
