import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/features/tasks/models/task_model.dart';

void main() {
  group('TaskStatus', () {
    test('should have correct display names', () {
      expect(TaskStatus.pending.displayName, 'Ausstehend');
      expect(TaskStatus.running.displayName, 'Läuft');
      expect(TaskStatus.completed.displayName, 'Abgeschlossen');
      expect(TaskStatus.failed.displayName, 'Fehlgeschlagen');
    });

    test('should parse from string correctly', () {
      expect(TaskStatus.fromString('running'), TaskStatus.running);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('failed'), TaskStatus.failed);
      expect(TaskStatus.fromString('pending'), TaskStatus.pending);
      expect(TaskStatus.fromString('unknown'), TaskStatus.pending); // default
    });
  });

  group('TaskModel', () {
    test('should create task with required fields', () {
      final task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        status: TaskStatus.pending,
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      expect(task.id, 'task-1');
      expect(task.name, 'Test Task');
      expect(task.status, TaskStatus.pending);
      expect(task.agent, isNull);
      expect(task.completedAt, isNull);
      expect(task.cronExpression, isNull);
      expect(task.errorMessage, isNull);
      expect(task.metadata, isNull);
    });

    test('should calculate duration when completed', () {
      final createdAt = DateTime(2024, 1, 15, 10, 0);
      final completedAt = DateTime(2024, 1, 15, 10, 30);

      final task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        status: TaskStatus.completed,
        createdAt: createdAt,
        completedAt: completedAt,
      );

      expect(task.duration, const Duration(minutes: 30));
    });

    test('should return null duration when not completed', () {
      final task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        status: TaskStatus.running,
        createdAt: DateTime.now(),
      );

      expect(task.duration, isNull);
    });

    test('should serialize to JSON', () {
      final task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        status: TaskStatus.running,
        agent: 'coding-agent',
        createdAt: DateTime(2024, 1, 15, 10, 0),
        completedAt: DateTime(2024, 1, 15, 10, 30),
        cronExpression: '0 * * * *',
        errorMessage: null,
        metadata: {'key': 'value'},
      );

      final json = task.toJson();

      expect(json['id'], 'task-1');
      expect(json['name'], 'Test Task');
      expect(json['status'], 'running');
      expect(json['agent'], 'coding-agent');
      expect(json['cron_expression'], '0 * * * *');
      expect(json['metadata'], {'key': 'value'});
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'task-1',
        'name': 'Test Task',
        'status': 'completed',
        'agent': 'coding-agent',
        'created_at': '2024-01-15T10:00:00.000',
        'completed_at': '2024-01-15T10:30:00.000',
        'cron_expression': '0 * * * *',
        'error_message': null,
        'metadata': null,
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, 'task-1');
      expect(task.name, 'Test Task');
      expect(task.status, TaskStatus.completed);
      expect(task.agent, 'coding-agent');
      expect(task.createdAt, DateTime(2024, 1, 15, 10, 0));
      expect(task.completedAt, DateTime(2024, 1, 15, 10, 30));
      expect(task.cronExpression, '0 * * * *');
    });

    test('should create copy with modified fields', () {
      final original = TaskModel(
        id: 'task-1',
        name: 'Original Task',
        status: TaskStatus.pending,
        createdAt: DateTime(2024, 1, 15, 10, 0),
      );

      final modified = original.copyWith(
        name: 'Modified Task',
        status: TaskStatus.running,
        agent: 'research-agent',
      );

      expect(original.name, 'Original Task');
      expect(original.status, TaskStatus.pending);
      expect(original.agent, isNull);

      expect(modified.name, 'Modified Task');
      expect(modified.status, TaskStatus.running);
      expect(modified.agent, 'research-agent');
    });
  });
}