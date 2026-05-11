import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/chat_export_service.dart';
import '../../core/services/chat_persistence_service.dart';
import '../../core/services/haptic_service.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/skeleton_loaders.dart';

/// Screen for exporting chat messages in various formats
class ChatExportScreen extends StatefulWidget {
  const ChatExportScreen({super.key});

  @override
  State<ChatExportScreen> createState() => _ChatExportScreenState();
}

class _ChatExportScreenState extends State<ChatExportScreen> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isExporting = false;
  final Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await ChatPersistenceService.loadMessages();
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Export'),
        centerTitle: true,
        actions: [
          if (_selectedChatIds.isNotEmpty)
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Iconsax.close_square, size: 20),
              label: Text('${_selectedChatIds.length} ausgewählt'),
            ),
        ],
      ),
      body: _isLoading
          ? const SettingsScreenSkeleton()
          : _messages.isEmpty
              ? _buildEmptyState(isDark)
              : _buildContent(isDark),
      bottomNavigationBar: _messages.isNotEmpty ? _buildExportOptions(isDark) : null,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.messages_bubble_outline,
            size: 64,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine Chats zum Exportieren',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Starte einen Chat, um ihn später exportieren zu können.',
            style: TextStyle(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    // Group messages by agent/date for display
    final groupedMessages = _groupMessagesForDisplay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${_messages.length} Nachrichten verfügbar',
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _selectAll(groupedMessages),
                child: const Text('Alle auswählen'),
              ),
            ],
          ),
        ),

        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: groupedMessages.length,
            itemBuilder: (context, index) {
              final entry = groupedMessages.entries.elementAt(index);
              return _buildChatGroup(entry.key, entry.value, isDark);
            },
          ),
        ),
      ],
    );
  }

  Map<String, List<ChatMessage>> _groupMessagesForDisplay() {
    // Group by agent + date for display
    final grouped = <String, List<ChatMessage>>{};
    
    for (final msg in _messages) {
      final agent = msg.agentName ?? 'General';
      final dateKey = _formatDate(msg.timestamp);
      final key = '$agent - $dateKey';
      grouped.putIfAbsent(key, () => []).add(msg);
    }
    
    return grouped;
  }

  Widget _buildChatGroup(String title, List<ChatMessage> messages, bool isDark) {
    final groupId = title.hashCode.toString();
    final isSelected = _selectedChatIds.contains(groupId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: () => _toggleGroupSelection(groupId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  isSelected ? Iconsax.check_circle : Iconsax.circle,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.split(' - ')[0], // Agent name
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      Text(
                        '${messages.length} Nachrichten • ${title.split(' - ')[1]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Iconsax.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),

        // Preview of messages
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: messages.take(3).map((msg) {
              final prefix = msg.type == MessageType.user ? 'Du: ' : 'AI: ';
              final content = msg.content.length > 60 
                  ? '${msg.content.substring(0, 60)}...' 
                  : msg.content;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$prefix$content',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExportOptions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format wählen',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ExportButton(
                    icon: Iconsax.code,
                    label: 'JSON',
                    color: AppColors.primary,
                    onTap: () => _exportAsJson(),
                    isLoading: _isExporting,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ExportButton(
                    icon: Iconsax.text_block,
                    label: 'Text',
                    color: AppColors.secondary,
                    onTap: () => _exportAsText(),
                    isLoading: _isExporting,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ExportButton(
                    icon: Iconsax.paperclip,
                    label: 'PDF',
                    color: AppColors.error,
                    onTap: () => _exportAsPdf(),
                    isLoading: _isExporting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedChatIds.contains(groupId)) {
        _selectedChatIds.remove(groupId);
      } else {
        _selectedChatIds.add(groupId);
      }
    });
    HapticService.lightImpact();
  }

  void _selectAll(Map<String, List<ChatMessage>> grouped) {
    setState(() {
      if (_selectedChatIds.length == grouped.length) {
        _selectedChatIds.clear();
      } else {
        _selectedChatIds.clear();
        _selectedChatIds.addAll(grouped.keys);
      }
    });
    HapticService.lightImpact();
  }

  void _clearSelection() {
    setState(() => _selectedChatIds.clear());
    HapticService.lightImpact();
  }

  List<ChatMessage> _getSelectedMessages() {
    if (_selectedChatIds.isEmpty) return _messages;
    
    final grouped = _groupMessagesForDisplay();
    final selectedMessages = <ChatMessage>[];
    
    for (final id in _selectedChatIds) {
      if (grouped.containsKey(id)) {
        selectedMessages.addAll(grouped[id]!);
      }
    }
    
    return selectedMessages.isEmpty ? _messages : selectedMessages;
  }

  Future<void> _exportAsJson() async {
    setState(() => _isExporting = true);
    
    try {
      final messages = _getSelectedMessages();
      final json = ChatPersistenceService.exportAsJson(messages);
      await ChatExportService.shareExport(json, 'clawchat_export.json');
      HapticService.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('JSON Export erfolgreich'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showExportError();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAsText() async {
    setState(() => _isExporting = true);
    
    try {
      final messages = _getSelectedMessages();
      final text = ChatPersistenceService.exportAsText(messages);
      await ChatExportService.shareExport(text, 'clawchat_export.txt');
      HapticService.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Text Export erfolgreich'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showExportError();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAsPdf() async {
    setState(() => _isExporting = true);
    
    try {
      final messages = _getSelectedMessages();
      final pdfBytes = await ChatExportService.exportAsPdf(messages);
      await ChatExportService.sharePdf(pdfBytes, 'clawchat_export.pdf');
      HapticService.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF Export erfolgreich'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showExportError();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.warning_2, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Export fehlgeschlagen'),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    
    if (date == today) return 'Heute';
    if (date == today.subtract(const Duration(days: 1))) return 'Gestern';
    
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}