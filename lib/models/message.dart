enum MessageType { user, assistant, system, thinking, toolCall, streaming }

enum MessageStatus { sending, sent, delivered, read, error }

class MessageAttachment {
  final String path;
  final String fileName;
  final String mimeType;
  final int? size;
  final String? url; // Remote URL for received attachments

  MessageAttachment({
    required this.path,
    required this.fileName,
    this.mimeType = 'image/jpeg',
    this.size,
    this.url, // Optional remote URL
  });
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? agentName;
  final Map<String, dynamic>? toolData;
  final List<MessageAttachment>? attachments;
  final Map<String, int>? reactions; // emoji -> count
  final bool isStreaming; // true while assistant is streaming this message
  final List<String>? streamingChunks; // accumulated chunks for display
  final bool isEdited; // true if message was edited
  final String? replyToId; // ID of the message being replied to
  final String? replyToContent; // Preview of the message being replied to
  final DateTime? readAt; // Timestamp when message was read

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.agentName,
    this.toolData,
    this.attachments,
    this.reactions,
    this.isStreaming = false,
    this.streamingChunks,
    this.isEdited = false,
    this.replyToId,
    this.replyToContent,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    MessageType parseType(String? value) {
      switch (value) {
        case 'assistant': return MessageType.assistant;
        case 'system': return MessageType.system;
        case 'thinking': return MessageType.thinking;
        case 'toolCall': return MessageType.toolCall;
        case 'streaming': return MessageType.streaming;
        default: return MessageType.user;
      }
    }

    MessageStatus parseStatus(String? value) {
      switch (value) {
        case 'sending': return MessageStatus.sending;
        case 'delivered': return MessageStatus.delivered;
        case 'read': return MessageStatus.read;
        case 'error': return MessageStatus.error;
        default: return MessageStatus.sent;
      }
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: parseType(json['type'] as String?),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      status: parseStatus(json['status'] as String?),
      agentName: json['agentName'] as String?,
      toolData: json['toolData'] is Map ? Map<String, dynamic>.from(json['toolData'] as Map) : null,
      reactions: json['reactions'] is Map
          ? Map<String, int>.from(json['reactions'] as Map)
          : null,
      isStreaming: json['isStreaming'] == true,
      isEdited: json['isEdited'] == true,
      replyToId: json['replyToId'] as String?,
      replyToContent: json['replyToContent'] as String?,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
    );
  }

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    Map<String, dynamic>? toolData,
    List<MessageAttachment>? attachments,
    Map<String, int>? reactions,
    bool? isStreaming,
    List<String>? streamingChunks,
    bool? isEdited,
    String? replyToId,
    String? replyToContent,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      agentName: agentName ?? this.agentName,
      toolData: toolData ?? this.toolData,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingChunks: streamingChunks ?? this.streamingChunks,
      isEdited: isEdited ?? this.isEdited,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      readAt: readAt ?? this.readAt,
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

class AgentPreset {
  final String id;
  final String name;
  final String agentId;
  final String? systemPrompt;
  final Map<String, dynamic>? customParams;
  final DateTime createdAt;

  AgentPreset({
    required this.id,
    required this.name,
    required this.agentId,
    this.systemPrompt,
    this.customParams,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'agentId': agentId,
    'systemPrompt': systemPrompt,
    'customParams': customParams,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AgentPreset.fromJson(Map<String, dynamic> json) => AgentPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    agentId: json['agentId'] as String,
    systemPrompt: json['systemPrompt'] as String?,
    customParams: json['customParams'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  AgentPreset copyWith({
    String? name,
    String? agentId,
    String? systemPrompt,
    Map<String, dynamic>? customParams,
  }) {
    return AgentPreset(
      id: id,
      name: name ?? this.name,
      agentId: agentId ?? this.agentId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      customParams: customParams ?? this.customParams,
      createdAt: createdAt,
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