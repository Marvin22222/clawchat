enum TaskStatus {
  pending,
  running,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Ausstehend';
      case TaskStatus.running:
        return 'Läuft';
      case TaskStatus.completed:
        return 'Abgeschlossen';
      case TaskStatus.failed:
        return 'Fehlgeschlagen';
    }
  }

  static TaskStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return TaskStatus.running;
      case 'completed':
        return TaskStatus.completed;
      case 'failed':
        return TaskStatus.failed;
      default:
        return TaskStatus.pending;
    }
  }
}

class TaskModel {
  final String id;
  final String name;
  final TaskStatus status;
  final String? agent;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? cronExpression;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  TaskModel({
    required this.id,
    required this.name,
    required this.status,
    this.agent,
    required this.createdAt,
    this.completedAt,
    this.cronExpression,
    this.errorMessage,
    this.metadata,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: TaskStatus.fromString(json['status'] as String),
      agent: json['agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cronExpression: json['cron_expression'] as String?,
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'agent': agent,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cron_expression': cronExpression,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  TaskModel copyWith({
    String? id,
    String? name,
    TaskStatus? status,
    String? agent,
    DateTime? createdAt,
    DateTime? completedAt,
    String? cronExpression,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      agent: agent ?? this.agent,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cronExpression: cronExpression ?? this.cronExpression,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }
}
