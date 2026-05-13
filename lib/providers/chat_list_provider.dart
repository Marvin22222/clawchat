import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../models/session.dart';

/// Chat list provider to manage sessions with read/unread state
class ChatListProvider extends ChangeNotifier {
  final List<_ChatItem> _chats = [];
  
  List<_ChatItem> get chats => List.unmodifiable(_chats);
  
  // Get chats sorted: unread first, then by last message time
  List<_ChatItem> get sortedChats {
    final sorted = List<_ChatItem>.from(_chats);
    sorted.sort((a, b) {
      // Unread first
      if (a.isUnread != b.isUnread) {
        return a.isUnread ? -1 : 1;
      }
      // Then by last message time (most recent first)
      final aTime = a.session.lastMessageAt ?? a.session.createdAt;
      final bTime = b.session.lastMessageAt ?? b.session.createdAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  void addChat(Session session) {
    _chats.insert(0, _ChatItem(session: session));
    notifyListeners();
  }

  void updateChat(Session session) {
    final index = _chats.indexWhere((c) => c.session.id == session.id);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(session: session);
      notifyListeners();
    }
  }

  void markAsRead(String sessionId) {
    final index = _chats.indexWhere((c) => c.session.id == sessionId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(isUnread: false);
      notifyListeners();
    }
  }

  void markAsUnread(String sessionId) {
    final index = _chats.indexWhere((c) => c.session.id == sessionId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(isUnread: true);
      notifyListeners();
    }
  }

  void deleteChat(String sessionId) {
    _chats.removeWhere((c) => c.session.id == sessionId);
    notifyListeners();
  }

  void archiveChat(String sessionId) {
    // Move to archived list (implementation depends on requirements)
    deleteChat(sessionId);
  }

  void undoDelete(Session session) {
    _chats.insert(0, _ChatItem(session: session, isUnread: true));
    notifyListeners();
  }

  void setChats(List<Session> sessions) {
    _chats.clear();
    for (final session in sessions) {
      _chats.add(_ChatItem(session: session));
    }
    notifyListeners();
  }

  void clearAll() {
    _chats.clear();
    notifyListeners();
  }
}

class _ChatItem {
  final Session session;
  final bool isUnread;

  _ChatItem({
    required this.session,
    this.isUnread = true,
  });

  _ChatItem copyWith({
    Session? session,
    bool? isUnread,
  }) {
    return _ChatItem(
      session: session ?? this.session,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}