import 'package:uuid/uuid.dart';
import 'agent_status.dart';

/// Represents a single agent session with status and task info
class AgentSession {
  final String id;
  final String name;
  final String? role; // e.g. "coding", "research", "main"
  final AgentStatus status;
  final String? currentTask;
  final double progress; // 0.0 - 1.0
  final List<String> steps;
  final DateTime? lastActive;
  final DateTime? startedAt;

  AgentSession({
    String? id,
    required this.name,
    this.role,
    this.status = AgentStatus.idle,
    this.currentTask,
    this.progress = 0.0,
    this.steps = const [],
    this.lastActive,
    DateTime? startedAt,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  AgentSession copyWith({
    String? name,
    String? role,
    AgentStatus? status,
    String? currentTask,
    double? progress,
    List<String>? steps,
    DateTime? lastActive,
  }) {
    return AgentSession(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      progress: progress ?? this.progress,
      steps: steps ?? this.steps,
      lastActive: lastActive ?? this.lastActive,
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'status': status.name,
      'currentTask': currentTask,
      'progress': progress,
      'steps': steps,
      'lastActive': lastActive?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  factory AgentSession.fromJson(Map<String, dynamic> json) {
    return AgentSession(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      status: AgentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AgentStatus.idle,
      ),
      currentTask: json['currentTask'],
      progress: (json['progress'] ?? 0.0).toDouble(),
      steps: List<String>.from(json['steps'] ?? []),
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
    );
  }

  /// Get avatar emoji based on role
  String get avatarEmoji {
    if (role == null) return '🤖';
    switch (role!.toLowerCase()) {
      case 'coding':
        return '👾';
      case 'research':
        return '🔍';
      case 'autotask':
        return '⚡';
      case 'main':
        return '🤖';
      default:
        return '🎭';
    }
  }

  /// Get duration string for display
  String get durationString {
    if (startedAt == null) return '';
    final duration = DateTime.now().difference(startedAt!);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}
