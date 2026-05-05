import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/models/session.dart';

void main() {
  group('Session Model', () {
    test('should create session with required fields', () {
      final session = Session(
        name: 'Test Chat',
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      expect(session.name, 'Test Chat');
      expect(session.messageCount, 0);
      expect(session.isActive, true);
      expect(session.agentId, isNull);
    });

    test('should create session with auto-generated id', () {
      final session1 = Session(name: 'Chat 1');
      final session2 = Session(name: 'Chat 2');

      expect(session1.id, isNotEmpty);
      expect(session2.id, isNotEmpty);
      expect(session1.id, isNot(equals(session2.id)));
    });

    test('should create copy with modified fields', () {
      final original = Session(
        name: 'Original Chat',
        messageCount: 5,
      );

      final modified = original.copyWith(
        name: 'Modified Chat',
        messageCount: 10,
        agentId: 'agent-123',
      );

      expect(original.name, 'Original Chat');
      expect(original.messageCount, 5);
      expect(original.agentId, isNull);

      expect(modified.name, 'Modified Chat');
      expect(modified.messageCount, 10);
      expect(modified.agentId, 'agent-123');
    });

    test('should serialize to JSON', () {
      final session = Session(
        id: 'test-id',
        name: 'Test Chat',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        messageCount: 15,
        agentId: 'agent-123',
        isActive: true,
      );

      final json = session.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Chat');
      expect(json['messageCount'], 15);
      expect(json['agentId'], 'agent-123');
      expect(json['isActive'], true);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Chat',
        'createdAt': '2024-01-15T10:30:00.000',
        'lastMessageAt': '2024-01-15T11:00:00.000',
        'messageCount': 15,
        'agentId': 'agent-123',
        'isActive': true,
      };

      final session = Session.fromJson(json);

      expect(session.id, 'test-id');
      expect(session.name, 'Test Chat');
      expect(session.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(session.lastMessageAt, DateTime(2024, 1, 15, 11, 0));
      expect(session.messageCount, 15);
      expect(session.agentId, 'agent-123');
      expect(session.isActive, true);
    });

    test('should handle null optional fields in JSON', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Chat',
        'createdAt': '2024-01-15T10:30:00.000',
        'messageCount': 5,
        'isActive': true,
      };

      final session = Session.fromJson(json);

      expect(session.lastMessageAt, isNull);
      expect(session.agentId, isNull);
    });
  });

  group('SessionManager', () {
    test('should create and store sessions', () {
      final manager = SessionManager();

      expect(manager.sessions, isEmpty);

      final session = manager.createSession(name: 'New Chat');

      expect(manager.sessions.length, 1);
      expect(manager.sessions.first.name, 'New Chat');
    });

    test('should track active sessions', () {
      final manager = SessionManager();

      final session1 = manager.createSession(name: 'Chat 1');
      final session2 = manager.createSession(name: 'Chat 2');

      expect(manager.activeSessions.length, 2);

      // Deactivate one
      final modified = session1.copyWith(isActive: false);
      expect(modified.isActive, false);
    });

    test('should return unmodifiable sessions list', () {
      final manager = SessionManager();
      manager.createSession(name: 'Chat 1');

      expect(() => (manager.sessions as List).clear(), throwsA(anything));
    });
  });
}