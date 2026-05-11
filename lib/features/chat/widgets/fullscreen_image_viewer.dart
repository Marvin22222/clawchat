import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

class FullscreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String? imageUrl; // Remote URL for received images
  final bool isDark;

  const FullscreenImageViewer({
    super.key,
    required this.imagePath,
    this.imageUrl,
    this.isDark = false,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    final bool isRemote = widget.imageUrl != null;
    final String heroTag = 'image_\${widget.imagePath}_\${widget.imageUrl ?? ''}';

    Widget imageWidget;
    if (isRemote) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: AppSpacing.md),
              Text('Bild konnte nicht geladen werden', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    } else {
      imageWidget = Image.file(
        File(widget.imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.broken_image, color: Colors.white54, size: 64),
                SizedBox(height: AppSpacing.md),
                Text('Bild konnte nicht geladen werden', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        },
      );
    }

    return Hero(
      tag: heroTag,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Foto', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _transformationController.value = Matrix4.identity()..scale(2.0);
              setState(() => _currentScale = 2.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
              setState(() => _currentScale = 1.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
              setState(() => _currentScale = 1.0);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          onInteractionUpdate: (details) {
            setState(() => _currentScale = _transformationController.value.getMaxScaleOnAxis());
          },
          child: _buildImage(),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${(_currentScale * 100).toInt()}%', style: const TextStyle(color: Colors.white54)),
              const SizedBox(width: AppSpacing.md),
              const Text('Pinch zum Zoomen', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
