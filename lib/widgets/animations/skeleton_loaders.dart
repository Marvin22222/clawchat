import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';

/// Skeleton loading placeholders for content loading states
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool animate;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.small,
    this.animate = true,
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