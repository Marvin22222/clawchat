import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Image quality presets
enum ImageQualityPreset {
  high,    // 2MB max, 2048px
  medium,  // 1MB max, 1920px  
  low,     // 500KB max, 1280px
}

extension ImageQualityPresetExtension on ImageQualityPreset {
  String get value {
    switch (this) {
      case ImageQualityPreset.high:
        return 'high';
      case ImageQualityPreset.medium:
        return 'medium';
      case ImageQualityPreset.low:
        return 'low';
    }
  }

  String get displayName {
    switch (this) {
      case ImageQualityPreset.high:
        return 'Hoch';
      case ImageQualityPreset.medium:
        return 'Mittel';
      case ImageQualityPreset.low:
        return 'Niedrig';
    }
  }

  int get maxSizeKb {
    switch (this) {
      case ImageQualityPreset.high:
        return 2048;  // 2MB
      case ImageQualityPreset.medium:
        return 1024;  // 1MB
      case ImageQualityPreset.low:
        return 500;   // 500KB
    }
  }

  int get maxDimension {
    switch (this) {
      case ImageQualityPreset.high:
        return 2048;
      case ImageQualityPreset.medium:
        return 1920;
      case ImageQualityPreset.low:
        return 1280;
    }
  }

  int get quality {
    switch (this) {
      case ImageQualityPreset.high:
        return 90;
      case ImageQualityPreset.medium:
        return 80;
      case ImageQualityPreset.low:
        return 60;
    }
  }

  static ImageQualityPreset fromString(String? value) {
    switch (value) {
      case 'high':
        return ImageQualityPreset.high;
      case 'low':
        return ImageQualityPreset.low;
      case 'medium':
      default:
        return ImageQualityPreset.medium;
    }
  }
}

class ImageCompressionResult {
  final File compressedFile;
  final int originalSizeKb;
  final int compressedSizeKb;
  final double compressionRatio;

  ImageCompressionResult({
    required this.compressedFile,
    required this.originalSizeKb,
    required this.compressedSizeKb,
    required this.compressionRatio,
  });

  String get formattedOriginal => _formatSize(originalSizeKb);
  String get formattedCompressed => _formatSize(compressedSizeKb);

  String _formatSize(int kb) {
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)}MB';
    }
    return '${kb}KB';
  }
}

/// Service for compressing images before upload
class ImageCompressionService {
  static const String _keyImageQuality = 'image_quality';

  /// Get current image quality preset from storage
  static Future<ImageQualityPreset> getQualityPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyImageQuality);
    return ImageQualityPresetExtension.fromString(value);
  }

  /// Set image quality preset
  static Future<void> setQualityPreset(ImageQualityPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImageQuality, preset.value);
  }

  /// Compress image file
  /// Returns compressed file or original if compression fails
  static Future<ImageCompressionResult?> compress(
    String imagePath, {
    ImageQualityPreset? preset,
  }) async {
    try {
      final quality = preset ?? await getQualityPreset();
      
      final originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        return null;
      }

      final originalBytes = await originalFile.readAsBytes();
      final originalSizeKb = (originalBytes.length / 1024).round();

      // Skip compression if already small enough
      if (originalSizeKb <= quality.maxSizeKb) {
        return ImageCompressionResult(
          compressedFile: originalFile,
          originalSizeKb: originalSizeKb,
          compressedSizeKb: originalSizeKb,
          compressionRatio: 1.0,
        );
      }

      // Use compute for CPU-intensive compression
      final compressedBytes = await compute(
        _compressImageBytes,
        _CompressionParams(
          bytes: originalBytes,
          maxDimension: quality.maxDimension,
          quality: quality.quality,
          maxSizeKb: quality.maxSizeKb,
        ),
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        return null;
      }

      final compressedSizeKb = (compressedBytes.length / 1024).round();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imagePath.split('.').last.toLowerCase();
      final compressedPath = '${tempDir.path}/compressed_$timestamp.$extension';
      
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return ImageCompressionResult(
        compressedFile: compressedFile,
        originalSizeKb: originalSizeKb,
        compressedSizeKb: compressedSizeKb,
        compressionRatio: compressedSizeKb / originalSizeKb,
      );
    } catch (e) {
      return null;
    }
  }

  /// Compress multiple images
  static Future<List<ImageCompressionResult>> compressMultiple(
    List<String> imagePaths, {
    ImageQualityPreset? preset,
  }) async {
    final results = <ImageCompressionResult>[];
    for (final path in imagePaths) {
      final result = await compress(path, preset: preset);
      if (result != null) {
        results.add(result);
      }
    }
    return results;
  }

  /// Get human-readable size string
  static String formatSize(int bytes) {
    final kb = bytes / 1024;
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.round()} KB';
  }
}

/// Parameters for compression in isolate
class _CompressionParams {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;
  final int maxSizeKb;

  _CompressionParams({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
    required this.maxSizeKb,
  });
}

/// Compress image bytes in isolate
Uint8List? _compressImageBytes(_CompressionParams params) {
  try {
    // Decode image
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    // Calculate new dimensions maintaining aspect ratio
    int width = image.width;
    int height = image.height;

    if (width > params.maxDimension || height > params.maxDimension) {
      final ratio = width > height 
          ? params.maxDimension / width 
          : params.maxDimension / height;
      width = (width * ratio).round();
      height = (height * ratio).round();
      
      // Resize image
      final resized = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      // Encode with JPEG
      return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
    }

    // Already small enough, just re-encode
    return Uint8List.fromList(img.encodeJpg(image, quality: params.quality));
  } catch (e) {
    return null;
  }
}