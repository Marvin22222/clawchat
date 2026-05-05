import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/file_storage_service.dart';
import '../../models/message.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final FileStorageService _storageService = FileStorageService();
  List<StoredFile> _files = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'date'; // 'date', 'name', 'size'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _storageService.loadFiles();
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<StoredFile> get _sortedFiles {
    final sorted = List<StoredFile>.from(_files);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.fileName.compareTo(b.fileName));
        break;
      case 'size':
        sorted.sort((a, b) => a.fileSize.compareTo(b.fileSize));
        break;
      case 'date':
      default:
        sorted.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        break;
    }
    if (!_sortAscending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() => _isLoading = true);
          
          final storedFile = await _storageService.saveFile(
            filePath: file.path!,
            fileName: file.name,
            mimeType: _getMimeType(file.name),
          );

          setState(() {
            _files.add(storedFile);
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(Text('${file.name} hochgeladen')),
                  ],
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(Text('Upload fehlgeschlagen: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(StoredFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datei löschen?'),
        content: Text('"${file.fileName}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteFile(file.id);
      setState(() => _files.removeWhere((f) => f.id == file.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.fileName} gelöscht'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(StoredFile file) async {
    try {
      final localFile = await _storageService.getLocalFile(file.id);
      if (localFile != null && await localFile.exists()) {
        await Share.shareXFiles(
          [XFile(localFile.path)],
          text: 'Datei von ClawChat: ${file.fileName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teilen fehlgeschlagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _previewFile(StoredFile file) async {
    final localFile = await _storageService.getLocalFile(file.id);
    if (localFile == null || !await localFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datei nicht gefunden'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (_isImageFile(file.fileName)) {
      // Show image preview
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Image.file(
                    localFile,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _shareFile(file);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Teilen'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Schließen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // For non-image files, just share/open
      _shareFile(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dateien'),
        automaticallyImplyLeading: false,
        actions: [
          if (_files.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sortieren',
              onSelected: (value) {
                if (value == _sortBy) {
                  setState(() => _sortAscending = !_sortAscending);
                } else {
                  setState(() {
                    _sortBy = value;
                    _sortAscending = false;
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: _sortBy == 'date' ? AppColors.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nach Datum',
                        style: TextStyle(
                          fontWeight: _sortBy == 'date' ? FontWeight.bold : null,
                        ),
                      ),
                      if (_sortBy == 'date')
                        Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        size: 18,
                        color: _sortBy == 'name' ? AppColors.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nach Name',
                        style: TextStyle(
                          fontWeight: _sortBy == 'name' ? FontWeight.bold : null,
                        ),
                      ),
                      if (_sortBy == 'name')
                        Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'size',
                  child: Row(
                    children: [
                      Icon(
                        Icons.data_usage,
                        size: 18,
                        color: _sortBy == 'size' ? AppColors.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nach Größe',
                        style: TextStyle(
                          fontWeight: _sortBy == 'size' ? FontWeight.bold : null,
                        ),
                      ),
                      if (_sortBy == 'size')
                        Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadFile,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Fehler beim Laden',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Noch keine Dateien',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Dateien die du sendest erscheinen hier.\nTippe + um eine Datei hochzuladen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Datei hochladen'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Storage info bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.storage,
                size: 16,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_files.length} ${_files.length == 1 ? 'Datei' : 'Dateien'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _formatTotalSize(_totalSize),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _sortedFiles.length,
            itemBuilder: (context, index) {
              final file = _sortedFiles[index];
              return _FileCard(
                file: file,
                isDark: isDark,
                onTap: () => _previewFile(file),
                onShare: () => _shareFile(file),
                onDelete: () => _deleteFile(file),
              );
            },
          ),
        ),
      ],
    );
  }

  int get _totalSize {
    return _files.fold(0, (sum, file) => sum + file.fileSize);
  }

  String _formatTotalSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio/mpeg';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}

class _FileCard extends StatelessWidget {
  final StoredFile file;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _FileCard({
    required this.file,
    required this.isDark,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  IconData get _fileIcon {
    final ext = file.fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'js':
      case 'ts':
      case 'py':
      case 'dart':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
      case 'swift':
      case 'kt':
        return Icons.code;
      case 'json':
      case 'xml':
      case 'html':
      case 'css':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get _iconColor {
    final ext = file.fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return Colors.pink;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Colors.green;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return Colors.orange;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Colors.purple;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Colors.amber;
      case 'js':
      case 'ts':
      case 'py':
      case 'dart':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
      case 'swift':
      case 'kt':
        return Colors.cyan;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  _fileIcon,
                  color: _iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatFileSize(file.fileSize),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatDate(file.uploadedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                onPressed: onShare,
                tooltip: 'Teilen',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                onPressed: onDelete,
                tooltip: 'Löschen',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inHours < 1) return 'Vor ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Vor ${diff.inHours}h';
    if (diff.inDays < 7) return 'Vor ${diff.inDays}d';
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Model for stored files
class StoredFile {
  final String id;
  final String fileName;
  final String localPath;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;

  StoredFile({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory StoredFile.fromJson(Map<String, dynamic> json) {
    return StoredFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      localPath: json['localPath'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'localPath': localPath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

/// Service for file storage operations
class FileStorageService {
  static const String _metadataFileName = 'files_metadata.json';
  
  Future<String> get _storageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${appDir.path}/clawchat_files');
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return storageDir.path;
  }

  Future<String> get _metadataFilePath async {
    final dir = await _storageDir;
    return '$dir/$_metadataFileName';
  }

  Future<File> get _metadataFile async {
    final path = await _metadataFilePath;
    return File(path);
  }

  Future<List<StoredFile>> loadFiles() async {
    try {
      final file = await _metadataFile;
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList
          .map((e) => StoredFile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<StoredFile> saveFile({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final sourceFile = File(filePath);
    final fileSize = await sourceFile.length();
    
    final dir = await _storageDir;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = fileName.split('.').last;
    final newFileName = '$id${extension.isNotEmpty ? '.$extension' : ''}';
    final newPath = '$dir/$newFileName';
    
    await sourceFile.copy(newPath);

    final storedFile = StoredFile(
      id: id,
      fileName: fileName,
      localPath: newPath,
      mimeType: mimeType,
      fileSize: fileSize,
      uploadedAt: DateTime.now(),
    );

    final files = await loadFiles();
    files.add(storedFile);
    await _saveMetadata(files);

    return storedFile;
  }

  Future<void> deleteFile(String id) async {
    final files = await loadFiles();
    final file = files.firstWhere((f) => f.id == id, orElse: () => throw Exception('File not found'));
    
    final localFile = File(file.localPath);
    if (await localFile.exists()) {
      await localFile.delete();
    }

    files.removeWhere((f) => f.id == id);
    await _saveMetadata(files);
  }

  Future<File?> getLocalFile(String id) async {
    final files = await loadFiles();
    final file = files.firstWhere((f) => f.id == id, orElse: () => throw Exception('File not found'));
    final localFile = File(file.localPath);
    if (await localFile.exists()) {
      return localFile;
    }
    return null;
  }

  Future<void> _saveMetadata(List<StoredFile> files) async {
    final file = await _metadataFile;
    final jsonList = files.map((f) => f.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }
}
