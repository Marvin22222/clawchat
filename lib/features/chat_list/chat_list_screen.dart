import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../models/session.dart';
import '../../providers/chat_list_provider.dart';
import '../chat/chat_screen.dart';
import '../../widgets/animations/app_transitions.dart';

/// Chat list screen with unread-first sorting and swipe actions
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final Map<String, Session> _deletedSessions = {};
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDemoSessions();
  }

  void _loadDemoSessions() {
    final provider = context.read<ChatListProvider>();
    // Demo sessions for testing
    final demoSessions = [
      Session(
        id: '1',
        name: 'Main Agent',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
        messageCount: 15,
        isActive: true,
      ),
      Session(
        id: '2',
        name: 'Coding Helper',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        messageCount: 8,
        isActive: true,
      ),
      Session(
        id: '3',
        name: 'Research',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        messageCount: 25,
        isActive: false,
      ),
      Session(
        id: '4',
        name: 'Image Analyzer',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
        messageCount: 5,
        isActive: false,
      ),
      Session(
        id: '5',
        name: 'Voice Assistant',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 5)),
        messageCount: 12,
        isActive: false,
      ),
    ];
    
    // Mark some as unread for demo
    provider.setChats(demoSessions);
    provider.markAsUnread('1'); // Main Agent unread
    provider.markAsUnread('2'); // Coding Helper unread
    // Research, Image Analyzer, Voice Assistant are read (older)
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  List<_ChatItem> _filterChats(List<_ChatItem> chats, String query) {
    if (query.isEmpty) return chats;
    final lowerQuery = query.toLowerCase();
    return chats.where((chat) {
      return chat.session.name.toLowerCase().contains(lowerQuery) ||
          (chat.session.lastMessage?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  void _openChat(Session session, ChatListProvider provider) {
    provider.markAsRead(session.id);
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: ChatScreen(initialAgent: session.name.toLowerCase()),
      ),
    );
  }

  void _deleteChat(Session session, ChatListProvider provider, int index) {
    HapticFeedback.mediumImpact();
    _deletedSessions[session.id] = session;
    provider.deleteChat(session.id);
    
    _showUndoSnackbar(
      context,
      '${session.name} gelöscht',
      onUndo: () {
        provider.undoDelete(session);
      },
    );
  }

  void _archiveChat(Session session, ChatListProvider provider, int index) {
    HapticFeedback.mediumImpact();
    provider.archiveChat(session.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${session.name} archiviert'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUndoSnackbar(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Rückgängig',
          textColor: Colors.white,
          onPressed: onUndo,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Session session, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(
          'Chat löschen?',
          style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Möchtest du den Chat "${session.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'Löschen',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Iconsax.arrow_left, color: AppColors.textSecondary),
                onPressed: _toggleSearch,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Chats durchsuchen...',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(
                'Chats',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Iconsax.search_normal_1, color: AppColors.textSecondary),
              onPressed: _toggleSearch,
            ),
          if (_isSearching && _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: Consumer<ChatListProvider>(
        builder: (context, provider, _) {
          var chats = provider.sortedChats;
          final query = _searchController.text;
          
          if (_isSearching && query.isNotEmpty) {
            chats = _filterChats(chats, query);
          }

          if (chats.isEmpty) {
            return _isSearching
                ? _buildNoResultsState(isDark, query)
                : _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatListItem(
                chat: chat,
                isDark: isDark,
                onTap: () => _openChat(chat.session, provider),
                onDelete: () => _showDeleteConfirmation(
                  chat.session,
                  () => _deleteChat(chat.session, provider, index),
                ),
                onArchive: () => _archiveChat(chat.session, provider, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_normal_1,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine Ergebnisse gefunden',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Für "$query"',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.messages,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine Chats vorhanden',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Starte einen neuen Chat über den Home-Bildschirm',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatItem chat;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  const _ChatListItem({
    required this.chat,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.session.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left - Delete
          return false; // We handle it with confirmation dialog
        } else {
          // Swipe right - Archive
          onArchive();
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        color: AppColors.info,
        child: const Row(
          children: [
            Icon(Iconsax.archive_1, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Archivieren',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Löschen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Icon(Iconsax.trash, color: Colors.white),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildContent()),
                const SizedBox(width: AppSpacing.sm),
                _buildTrailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Center(
            child: Text(
              _getAvatarEmoji(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        if (chat.isUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bgPrimary,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getAvatarEmoji() {
    final name = chat.session.name.toLowerCase();
    if (name.contains('coding') || name.contains('dev')) return '👾';
    if (name.contains('research') || name.contains('search')) return '🔍';
    if (name.contains('image') || name.contains('vision')) return '🖼️';
    if (name.contains('voice') || name.contains('audio')) return '🎤';
    if (name.contains('main')) return '🤖';
    return '💬';
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                chat.session.name,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getLastMessagePreview(),
          style: AppTypography.captionSmall.copyWith(
            color: chat.isUnread ? AppColors.textSecondary : AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getLastMessagePreview() {
    // In real app, this would come from the session's messages
    final count = chat.session.messageCount;
    return 'Letzte Nachricht... ($count Nachrichten)';
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTime(chat.session.lastMessageAt ?? chat.session.createdAt),
          style: AppTypography.captionSmall.copyWith(
            color: chat.isUnread ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        if (chat.isUnread) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${chat.session.messageCount}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Jetzt';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Gestern';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}.${time.month.toString().padLeft(2, '0')}';
    }
  }
}
