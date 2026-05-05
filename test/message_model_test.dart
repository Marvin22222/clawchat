import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/models/message.dart';
import 'package:clawchat/features/chat/widgets/chat_widgets.dart';
import 'package:clawchat/core/constants/colors.dart';

void main() {
  group('ChatMessage Model', () {
    test('should create message with required fields', () {
      final message = ChatMessage(
        id: '1',
        content: 'Hello World',
        type: MessageType.user,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(message.id, '1');
      expect(message.content, 'Hello World');
      expect(message.type, MessageType.user);
      expect(message.timestamp, DateTime(2024, 1, 15, 10, 30));
      expect(message.status, MessageStatus.sent);
      expect(message.isStreaming, false);
      expect(message.isEdited, false);
    });

    test('should create copy with modified fields', () {
      final original = ChatMessage(
        id: '1',
        content: 'Original',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(
        content: 'Modified',
        status: MessageStatus.sending,
      );

      expect(original.content, 'Original');
      expect(modified.content, 'Modified');
      expect(modified.status, MessageStatus.sending);
      expect(modified.id, original.id);
    });

    test('should handle attachments', () {
      final attachment = MessageAttachment(
        path: '/path/to/image.jpg',
        fileName: 'image.jpg',
        mimeType: 'image/jpeg',
        size: 1024,
      );

      final message = ChatMessage(
        id: '1',
        content: 'Check this out',
        type: MessageType.user,
        timestamp: DateTime.now(),
        attachments: [attachment],
      );

      expect(message.attachments?.length, 1);
      expect(message.attachments?.first.fileName, 'image.jpg');
    });

    test('should handle reactions', () {
      final message = ChatMessage(
        id: '1',
        content: 'Nice!',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        reactions: {'👍': 3, '❤️': 1},
      );

      expect(message.reactions?['👍'], 3);
      expect(message.reactions?['❤️'], 1);
    });
  });

  group('Agent Model', () {
    test('should create agent with required fields', () {
      final agent = Agent(
        id: 'agent_1',
        name: 'Coding Assistant',
      );

      expect(agent.id, 'agent_1');
      expect(agent.name, 'Coding Assistant');
      expect(agent.isSelected, false);
    });

    test('should create copy with modified selection', () {
      final agent = Agent(
        id: 'agent_1',
        name: 'Assistant',
        description: 'A helpful assistant',
      );

      final selected = agent.copyWith(isSelected: true);

      expect(agent.isSelected, false);
      expect(selected.isSelected, true);
      expect(selected.name, 'Assistant');
    });
  });

  group('AgentPreset Model', () {
    test('should serialize and deserialize correctly', () {
      final preset = AgentPreset(
        id: 'preset_1',
        name: 'My Preset',
        agentId: 'agent_1',
        systemPrompt: 'You are helpful.',
        customParams: {'temperature': 0.7},
        createdAt: DateTime(2024, 1, 15),
      );

      final json = preset.toJson();
      final restored = AgentPreset.fromJson(json);

      expect(restored.id, preset.id);
      expect(restored.name, preset.name);
      expect(restored.agentId, preset.agentId);
      expect(restored.systemPrompt, preset.systemPrompt);
      expect(restored.customParams?['temperature'], 0.7);
    });
  });

  group('ToolCall Model', () {
    test('should create tool call with required fields', () {
      final toolCall = ToolCall(
        id: 'tool_1',
        toolName: 'web_search',
        status: 'running',
        startTime: DateTime.now(),
      );

      expect(toolCall.id, 'tool_1');
      expect(toolCall.toolName, 'web_search');
      expect(toolCall.status, 'running');
      expect(toolCall.progress, 0.0);
    });

    test('should update status and progress', () {
      final toolCall = ToolCall(
        id: 'tool_1',
        toolName: 'calculator',
        status: 'running',
        startTime: DateTime.now(),
        progress: 0.5,
      );

      final completed = toolCall.copyWith(
        status: 'success',
        endTime: DateTime.now(),
        output: {'result': 42},
        progress: 1.0,
      );

      expect(completed.status, 'success');
      expect(completed.output?['result'], 42);
      expect(completed.progress, 1.0);
    });
  });

  group('MessageType enum', () {
    test('should have all expected values', () {
      expect(MessageType.values, contains(MessageType.user));
      expect(MessageType.values, contains(MessageType.assistant));
      expect(MessageType.values, contains(MessageType.system));
      expect(MessageType.values, contains(MessageType.thinking));
      expect(MessageType.values, contains(MessageType.toolCall));
    });
  });

  group('MessageStatus enum', () {
    test('should have all expected values', () {
      expect(MessageStatus.values, contains(MessageStatus.sending));
      expect(MessageStatus.values, contains(MessageStatus.sent));
      expect(MessageStatus.values, contains(MessageStatus.error));
    });
  });
}