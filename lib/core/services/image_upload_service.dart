import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../utils/logger.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      AppLogger.debug('Image picker error: $e', tag: 'UPLOAD');
      return null;
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      AppLogger.debug('Multi image picker error: $e', tag: 'UPLOAD');
      return [];
    }
  }

  Future<File?> takePhoto() async {
    return pickImage(source: ImageSource.camera);
  }
}

class ImageUploadWidget extends StatelessWidget {
  final Function(File) onImageSelected;
  final bool isDark;

  const ImageUploadWidget({
    super.key,
    required this.onImageSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final service = ImageUploadService();

    return PopupMenuButton<String>(
      icon: Icon(
        Iconsax.add_photo_alternate,
        color: isDark ? AppColors.textDark : AppColors.textLight,
      ),
      onSelected: (value) async {
        File? image;
        switch (value) {
          case 'gallery':
            image = await service.pickImage();
            break;
          case 'camera':
            image = await service.takePhoto();
            break;
        }
        if (image != null) {
          onImageSelected(image);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              const Icon(Iconsax.gallery),
              const SizedBox(width: AppSpacing.sm),
              const Text('Aus Galerie'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              const Icon(Iconsax.camera),
              const SizedBox(width: AppSpacing.sm),
              const Text('Foto aufnehmen'),
            ],
          ),
        ),
      ],
    );
  }
}
