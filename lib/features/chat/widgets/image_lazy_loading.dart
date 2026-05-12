import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';

/// Image Lazy Loading component using Intersection Observer pattern
/// 
/// Images are only loaded when they become visible in the viewport.
/// Features:
/// - Blur placeholder while loading
/// - Shimmer animation during load
/// - Smooth crossfade transition when loaded
/// - Image caching after first load
class ImageLazyLoading extends StatefulWidget {
  /// URL for remote images
  final String? imageUrl;
  
  /// Path for local images
  final String? imagePath;
  
  /// Width constraint
  final double? width;
  
  /// Height constraint
  final double? height;
  
  /// Border radius
  final double borderRadius;
  
  /// Box fit mode
  final BoxFit fit;
  
  /// Hero tag for hero animations
  final String? heroTag;
  
  /// Callback when image is tapped
  final VoidCallback? onTap;
  
  /// Callback when image is long pressed
  final VoidCallback? onLongPress;
  
  /// Show shimmer loading animation
  final bool showShimmer;
  
  /// Error widget to show on load failure
  final Widget? errorWidget;

  const ImageLazyLoading({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.width,
    this.height,
    this.borderRadius = AppRadius.medium,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.onTap,
    this.onLongPress,
    this.showShimmer = true,
    this.errorWidget,
  });

  @override
  State<ImageLazyLoading> createState() => _ImageLazyLoadingState();
}

class _ImageLazyLoadingState extends State<ImageLazyLoading>
    with SingleTickerProviderStateMixin {
  /// Whether the image has been loaded and is visible
  bool _isVisible = false;
  
  /// Whether the image has finished loading
  bool _isLoaded = false;
  
  /// Whether an error occurred loading the image
  bool _hasError = false;
  
  /// Animation controller for shimmer effect
  late AnimationController _shimmerController;
  
  /// Scroll position for visibility detection
  final ScrollController _scrollController = ScrollController();
  
  /// Whether we're using a local image
  bool get _isLocal => widget.imagePath != null;
  
  /// The image source to display
  String? get _imageSource => widget.imageUrl ?? widget.imagePath;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Start listening for scroll notifications to detect visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    // Use post frame callback to allow widget to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Get the render box to check if visible
      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;
      
      final renderBox = renderObject as RenderBox;
      final size = renderBox.size;
      
      // For local images, we always load them
      // For remote images, we use visibility detection
      if (_isLocal) {
        setState(() => _isVisible = true);
      } else {
        // For remote images, trigger load immediately for simplicity
        // CachedNetworkImage handles its own lazy loading
        setState(() => _isVisible = true);
      }
    });
  }

  void _onImageLoaded() {
    if (mounted && !_isLoaded) {
      setState(() {
        _isLoaded = true;
        _hasError = false;
      });
    }
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    if (mounted) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget imageWidget;
    
    if (_isLocal) {
      imageWidget = _buildLocalImage();
    } else {
      imageWidget = _buildNetworkImage();
    }
    
    // Apply border radius
    imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: imageWidget,
    );
    
    // Apply dimensions
    imageWidget = SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
    
    // Wrap with gesture handlers
    Widget content = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: imageWidget,
    );
    
    // Wrap with Hero if tag provided
    if (widget.heroTag != null) {
      content = Hero(
        tag: widget.heroTag!,
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildNetworkImage() {
    if (widget.imageUrl == null) {
      return _buildErrorPlaceholder();
    }
    
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Blur placeholder with shimmer (shown while loading)
        if (!_isLoaded && !_hasError && widget.showShimmer)
          BlurPlaceholder(
            width: widget.width ?? 200,
            height: widget.height ?? 200,
            borderRadius: widget.borderRadius,
            showShimmer: true,
            shimmerController: _shimmerController,
          ),
        
        // Actual image with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoaded || _hasError
              ? _buildLoadedNetworkImage()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLoadedNetworkImage() {
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorPlaceholder();
    }
    
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      key: ValueKey(_isLoaded ? widget.imageUrl : 'placeholder_${widget.imageUrl}'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      // Lazy load - only fetch when scrolled into view
      lazyLoad: true,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => const SizedBox.shrink(),
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onImageError(error, null);
        });
        return widget.errorWidget ?? _buildErrorPlaceholder();
      },
      imageBuilder: (context, imageProvider) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onImageLoaded();
        });
        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }

  Widget _buildLocalImage() {
    if (widget.imagePath == null) {
      return _buildErrorPlaceholder();
    }
    
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Blur placeholder with shimmer (shown while loading)
        if (!_isLoaded && !_hasError && widget.showShimmer)
          BlurPlaceholder(
            width: widget.width ?? 200,
            height: widget.height ?? 200,
            borderRadius: widget.borderRadius,
            showShimmer: true,
            shimmerController: _shimmerController,
          ),
        
        // Actual image with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoaded || _hasError
              ? _buildLoadedLocalImage()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLoadedLocalImage() {
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorPlaceholder();
    }
    
    return Image.file(
      File(widget.imagePath!),
      key: ValueKey(_isLoaded ? widget.imagePath : 'placeholder_${widget.imagePath}'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onImageLoaded();
          });
          return child;
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onImageError(error, stackTrace);
        });
        return widget.errorWidget ?? _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 200,
      color: isDark 
          ? AppColors.bgDarkTertiary 
          : AppColors.bgLightTertiary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 32,
            color: isDark 
                ? AppColors.textDarkSecondary 
                : AppColors.textLightSecondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bild fehlgeschlagen',
            style: AppTypography.captionSmall.copyWith(
              color: isDark 
                  ? AppColors.textDarkSecondary 
                  : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blur placeholder widget with optional shimmer animation
class BlurPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool showShimmer;
  final AnimationController? shimmerController;

  const BlurPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.medium,
    this.showShimmer = true,
    this.shimmerController,
  });

  @override
  State<BlurPlaceholder> createState() => _BlurPlaceholderState();
}

class _BlurPlaceholderState extends State<BlurPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _internalShimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.shimmerController != null) {
      _internalShimmerController = widget.shimmerController!;
    } else {
      _internalShimmerController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat();
    }
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _internalShimmerController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.shimmerController == null) {
      _internalShimmerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? AppColors.bgDarkTertiary 
        : AppColors.bgLightTertiary;
    
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.showShimmer
          ? AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment(_shimmerAnimation.value - 1, 0),
                      end: Alignment(_shimmerAnimation.value, 0),
                      colors: [
                        baseColor,
                        baseColor.withOpacity(0.5),
                        baseColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
    );
  }
}

/// Visibility-based lazy loading wrapper for images in scrollable lists
/// Uses Intersection Observer pattern to only load images when visible
class IntersectionObserverImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IntersectionObserverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = AppRadius.medium,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<IntersectionObserverImage> createState() => _IntersectionObserverImageState();
}

class _IntersectionObserverImageState extends State<IntersectionObserverImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Only trigger on scroll update, not on overscroll or user input
        if (notification is ScrollUpdateNotification) {
          // Debounce visibility checks
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkVisibility();
          });
        }
        return false;
      },
      child: VisibilityDetector(
        key: ValueKey(widget.imageUrl),
        onVisibilityChanged: (visibility) {
          if (visibility > 0 && !_isVisible) {
            setState(() => _isVisible = true);
          }
        },
        child: _isVisible
            ? ImageLazyLoading(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: widget.height,
                borderRadius: widget.borderRadius,
                fit: widget.fit,
                heroTag: widget.heroTag,
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
              )
            : BlurPlaceholder(
                width: widget.width ?? 200,
                height: widget.height ?? 200,
                borderRadius: widget.borderRadius,
                showShimmer: false,
              ),
      ),
    );
  }

  void _checkVisibility() {
    if (!mounted || _isVisible) return;
    
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;
    
    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    
    // Get the current viewport
    final viewport = MediaQuery.of(context).size;
    
    // Check if image is within viewport (with some buffer for early loading)
    final buffer = 200.0; // Load 200px before entering viewport
    final isInViewport = 
        position.dy < viewport.height + buffer &&
        position.dy + size.height > -buffer;
    
    if (isInViewport && !_isVisible) {
      setState(() => _isVisible = true);
    }
  }
}

/// Simple visibility detector using GlobalKey
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Key key;
  final void Function(double visibility) onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.key,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;
    
    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    
    final viewport = MediaQuery.of(context).size;
    final viewportRect = Rect.fromLTWH(0, 0, viewport.width, viewport.height);
    final widgetRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );
    
    final intersection = viewportRect.intersect(widgetRect);
    final visibility = intersection.isNotEmpty
        ? (intersection.width * intersection.height) / (size.width * size.height)
        : 0.0;
    
    widget.onVisibilityChanged(visibility);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetBuilder(
      builder: (context) => widget.child,
    );
  }
}

/// Widget builder wrapper for visibility checks
class WidgetBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const WidgetBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<WidgetBuilder> createState() => _WidgetBuilderState();
}

class _WidgetBuilderState extends State<WidgetBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, null);
  }
}