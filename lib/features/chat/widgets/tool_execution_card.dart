import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import 'package:iconsax/iconsax.dart';

enum ToolStatus { running, completed, error }

class ToolExecutionCard extends StatefulWidget {
  final String toolName;
  final String? toolDescription;
  final Map<String, dynamic>? parameters;
  final String? result;
  final ToolStatus status;
  final VoidCallback? onTap;

  const ToolExecutionCard({
    super.key,
    required this.toolName,
    this.toolDescription,
    this.parameters,
    this.result,
    this.status = ToolStatus.running,
    this.onTap,
  });

  @override
  State<ToolExecutionCard> createState() => _ToolExecutionCardState();
}

class _ToolExecutionCardState extends State<ToolExecutionCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
    widget.onTap?.call();
  }

  Color get _statusColor {
    switch (widget.status) {
      case ToolStatus.running:
        return Colors.orange;
      case ToolStatus.completed:
        return AppColors.success;
      case ToolStatus.error:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case ToolStatus.running:
        return Iconsax.clock_1;
      case ToolStatus.completed:
        return Icons.check_circle;
      case ToolStatus.error:
        return Iconsax.warning_2;
    }
  }

  IconData get _toolIcon {
    // Map tool names to icons
    final name = widget.toolName.toLowerCase();
    if (name.contains('search')) return Iconsax.search_normal_1;
    if (name.contains('calc') || name.contains('math')) return Iconsax.calculator;
    if (name.contains('code')) return Iconsax.code;
    if (name.contains('file')) return Iconsax.document;
    if (name.contains('web')) return Iconsax.global;
    if (name.contains('image')) return Iconsax.image;
    if (name.contains('weather')) return Iconsax.cloud;
    if (name.contains('time')) return Iconsax.clock;
    if (name.contains('music')) return Iconsax.music;
    if (name.contains('video')) return Iconsax.video;
    return Iconsax.heart; // default
  }

  @override
  Widget build(BuildContext context) {
    // Check accessibility settings
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    return Semantics(
      label: 'Werkzeugausführung: ${widget.toolName}',
      hint: widget.status == ToolStatus.running 
          ? 'Läuft, tippen für Details' 
          : 'Tippen für Details',
      child: Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Always visible
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Tool Icon with status badge
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Icon(
                          _toolIcon,
                          color: _statusColor,
                          size: 20,
                        ),
                      ),
                      if (widget.status == ToolStatus.running)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Tool info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.toolName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.status == ToolStatus.running
                                    ? 'Running'
                                    : widget.status == ToolStatus.completed
                                        ? 'Done'
                                        : 'Error',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.toolDescription != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.toolDescription!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand indicator
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Iconsax.arrow_down_1,
                      color: _statusColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          // Parameters
          if (widget.parameters != null && widget.parameters!.isNotEmpty) ...[
            Text(
              'Parameters',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                _formatJson(widget.parameters!),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Result
          if (widget.result != null) ...[
            Text(
              'Result',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.result!.length > 500
                    ? '${widget.result!.substring(0, 500)}...'
                    : widget.result!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    final entries = json.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      final value = entries[i].value;
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('  "$key": ${_formatValue(value)}$comma');
    }
    return '{\n${buffer.toString().trimRight()}\n}';
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is num || value is bool) return value.toString();
    if (value == null) return 'null';
    return value.toString();
  }
}
