enum MessageType { user, assistant, system, thinking, toolCall }

enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? agentName;
  final Map<String, dynamic>? toolData;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.agentName,
    this.toolData,
  });

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    Map<String, dynamic>? toolData,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      agentName: agentName ?? this.agentName,
      toolData: toolData ?? this.toolData,
    );
  }
}

class Agent {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isSelected;

  Agent({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isSelected = false,
  });

  Agent copyWith({bool? isSelected}) {
    return Agent(
      id: id,
      name: name,
      description: description,
      icon: icon,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ToolCall {
  final String id;
  final String toolName;
  final String status; // 'running', 'success', 'failed'
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final double progress;

  ToolCall({
    required this.id,
    required this.toolName,
    required this.status,
    required this.startTime,
    this.endTime,
    this.input,
    this.output,
    this.progress = 0.0,
  });

  ToolCall copyWith({
    String? status,
    DateTime? endTime,
    Map<String, dynamic>? output,
    double? progress,
  }) {
    return ToolCall(
      id: id,
      toolName: toolName,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      input: input ?? this.input,
      output: output ?? this.output,
      progress: progress ?? this.progress,
    );
  }
}
