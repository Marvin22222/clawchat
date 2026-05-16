import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;  // For search
  final int messageCount;
  final String? agentId;
  final bool isActive;

  Session({
    String? id,
    required this.name,
    DateTime? createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.messageCount = 0,
    this.agentId,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();


  Session copyWith({
    String? name,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? messageCount,
    String? agentId,
    bool? isActive,
  }) {
    return Session(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      messageCount: messageCount ?? this.messageCount,
      agentId: agentId ?? this.agentId,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage,
      'messageCount': messageCount,
      'agentId': agentId,
      'isActive': isActive,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      lastMessage: json['lastMessage'],
      messageCount: json['messageCount'] ?? 0,
      agentId: json['agentId'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class SessionManager {
  final List<Session> _sessions = [];
  
  List<Session> get sessions => List.unmodifiable(_sessions);
  List<Session> get activeSessions => _sessions.where((s) => s.isActive).toList();

  Session createSession({String? name, String? agentId}) {
    final session = Session(
      name: name ?? 'New Chat ${_sessions.length + 1}',
      agentId: agentId,
    );
    _sessions.insert(0, session);
    return session;
  }

  void updateSession(Session session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
    }
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
  }

  Session? getSession(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  void addMessageToSession(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(
        lastMessageAt: DateTime.now(),
        messageCount: _sessions[index].messageCount + 1,
      );
      // Move to top
      final session = _sessions.removeAt(index);
      _sessions.insert(0, session);
    }
  }
}
