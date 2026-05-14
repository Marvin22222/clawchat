import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/typography.dart';
import '../../../core/services/haptic_service.dart';

/// Inline video player widget for chat attachments
/// 
/// Features:
/// - Thumbnail preview before play
/// - Play/pause button overlay
/// - Progress bar with scrubbing
/// - Duration display
/// - Mute/unmute toggle
/// - Fullscreen option (opens native player)
/// - Dark/light mode support
class VideoPlayerWidget extends StatefulWidget {
  /// Local file path for the video
  final String? videoPath;
  
  /// Remote URL for the video
  final String? videoUrl;
  
  /// Whether dark mode is active
  final bool isDark;
  
  /// Width constraint
  final double? width;
  
  /// Height constraint
  final double? height;
  
  /// Border radius
  final double borderRadius;

  const VideoPlayerWidget({
    super.key,
    this.videoPath,
    this.videoUrl,
    required this.isDark,
    this.width,
    this.height,
    this.borderRadius = AppRadius.medium,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isBuffering = false;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoPath != null) {
        _controller = VideoPlayerController.file(File(widget.videoPath!));
      } else if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else {
        setState(() => _hasError = true);
        return;
      }

      await _controller!.initialize();
      
      _aspectRatio = _controller!.value.aspectRatio;
      
      _controller!.addListener(_onVideoUpdate);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller!.value.duration;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _controller == null) return;
    
    final value = _controller!.value;
    
    setState(() {
      _isPlaying = value.isPlaying;
      _position = value.position;
      _duration = value.duration;
      _isBuffering = value.isBuffering;
      
      if (value.hasError) {
        _hasError = true;
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    HapticService.lightImpact();
    
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _toggleMute() {
    if (_controller == null) return;
    
    HapticService.lightImpact();
    
    _isMuted = !_isMuted;
    _controller!.setVolume(_isMuted ? 0 : 1);
    setState(() {});
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
    setState(() => _position = position);
  }

  void _onSliderChanged(double value) {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    _seekTo(position);
  }

  void _openFullscreen() {
    // Open in native player using url_launcher or similar
    // For now, we'll use the system share sheet as a fallback
    if (widget.videoUrl != null) {
      // Could use url_launcher: WebView would open, share sheet for local files
      _showFullscreenPlayer();
    } else {
      _showFullscreenPlayer();
    }
  }

  void _showFullscreenPlayer() {
    if (_controller == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullscreenVideoPlayer(
        controller: _controller!,
        videoPath: widget.videoPath,
        videoUrl: widget.videoUrl,
        isDark: widget.isDark,
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? 240;
    final height = widget.height ?? 180;

    if (_hasError) {
      return _buildErrorWidget(width, height);
    }

    if (!_isInitialized) {
      return _buildLoadingWidget(width, height);
    }

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: width,
          height: height,
          color: widget.isDark ? Colors.black : Colors.grey[900],
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video
              if (_aspectRatio != null)
                AspectRatio(
                  aspectRatio: _aspectRatio!,
                  child: VideoPlayer(_controller!),
                ),
              
              // Buffering indicator
              if (_isBuffering)
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              
              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Center play/pause button
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Iconsax.pause : Iconsax.play,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            // Progress bar
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                                    : 0.0,
                                onChanged: _onSliderChanged,
                              ),
                            ),
                            
                            // Bottom row: duration, mute, fullscreen
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Time display
                                Text(
                                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                
                                // Action buttons
                                Row(
                                  children: [
                                    // Mute button
                                    GestureDetector(
                                      onTap: _toggleMute,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          _isMuted ? Iconsax.volume_slash : Iconsax.volume,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    
                                    // Fullscreen button
                                    GestureDetector(
                                      onTap: _openFullscreen,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.fullscreen,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: width,
        height: height,
        color: widget.isDark ? Colors.black : Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Video wird geladen...',
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: width,
        height: height,
        color: widget.isDark ? Colors.black : Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.video_remove,
                color: Colors.white54,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Video konnte nicht geladen werden',
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fullscreen video player shown in a modal bottom sheet
class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String? videoPath;
  final String? videoUrl;
  final bool isDark;

  const _FullscreenVideoPlayer({
    required this.controller,
    this.videoPath,
    this.videoUrl,
    required this.isDark,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
    _isPlaying = widget.controller.value.isPlaying;
    _duration = widget.controller.value.duration;
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {
      _isPlaying = widget.controller.value.isPlaying;
      _position = widget.controller.value.position;
      _duration = widget.controller.value.duration;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight,
      color: Colors.black,
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          children: [
            // Video centered
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Top bar with close button
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Iconsax.arrow_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Text(
                        'Vollbild',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer for alignment
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: (value) {
                            final position = Duration(
                              milliseconds: (value * _duration.inMilliseconds).round(),
                            );
                            widget.controller.seekTo(position);
                          },
                        ),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              // Play/Pause
                              GestureDetector(
                                onTap: () {
                                  if (_isPlaying) {
                                    widget.controller.pause();
                                  } else {
                                    widget.controller.play();
                                  }
                                  HapticService.lightImpact();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _isPlaying ? Iconsax.pause : Iconsax.play,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video thumbnail widget shown before playing
class VideoThumbnail extends StatelessWidget {
  final String? videoPath;
  final String? videoUrl;
  final bool isDark;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const VideoThumbnail({
    super.key,
    this.videoPath,
    this.videoUrl,
    required this.isDark,
    this.width = 200,
    this.height = 150,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          width: width,
          height: height,
          color: isDark ? Colors.black : Colors.grey[900],
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Placeholder gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              
              // Play button overlay
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.play,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              // Video icon in corner
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Iconsax.video,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
