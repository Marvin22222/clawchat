import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    // Demo sessions - in real app these would come from storage
    final sessions = [
      _SessionData(
        id: '1',
        name: 'Main Agent',
        lastMessage: 'Wie ist das Wetter heute?',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        messageCount: 12,
      ),
      _SessionData(
        id: '2',
        name: 'Coding Helper',
        lastMessage: 'Schreibe mir eine Python Funktion',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        messageCount: 8,
      ),
      _SessionData(
        id: '3',
        name: 'Research',
        lastMessage: 'Finde Infos über AI',
        time: DateTime.now().subtract(const Duration(days: 1)),
        messageCount: 25,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Verlauf'),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: isDark 
                        ? AppColors.textDarkSecondary 
                        : AppColors.textLightSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Noch keine Chats',
                    style: TextStyle(
                      color: isDark 
                          ? AppColors.textDarkSecondary 
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionCard(
                  session: session,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(initialAgent: session.name.toLowerCase()),
                      ),
                    );
                  },
                  onDelete: () {
                    // Delete session
                  },
                );
              },
            ),
    );
  }
}

class _SessionData {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime time;
  final int messageCount;

  _SessionData({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.messageCount,
  });
}

class _SessionCard extends StatelessWidget {
  final _SessionData session;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              session.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            session.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark 
                      ? AppColors.textDarkSecondary 
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(session.time),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? AppColors.textDarkSecondary 
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${session.messageCount}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}.${time.month}.';
    }
  }
}
