/// Message template model for canned responses
class MessageTemplate {
  final String id;
  final String title;
  final String content;
  final String? shortcut; // e.g., "/hello"
  final bool isCustom;
  final String category; // "quick", "code", "links", "custom"

  const MessageTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.shortcut,
    this.isCustom = false,
    this.category = 'quick',
  });

  /// Default templates
  static List<MessageTemplate> get defaultTemplates => [
    MessageTemplate(
      id: '1',
      title: 'Code teilen',
      content: 'Hier ist der Code:\n```\n\n```',
      shortcut: '/code',
      category: 'code',
    ),
    MessageTemplate(
      id: '2',
      title: 'Link teilen',
      content: 'Schau dir das an: ',
      shortcut: '/link',
      category: 'links',
    ),
    MessageTemplate(
      id: '3',
      title: 'Danke',
      content: 'Danke für die Hilfe! 🙏',
      shortcut: '/thanks',
      category: 'quick',
    ),
    MessageTemplate(
      id: '4',
      title: 'Frage',
      content: 'Kannst du mir dabei helfen?',
      shortcut: '/help',
      category: 'quick',
    ),
    MessageTemplate(
      id: '5',
      title: 'Hallo',
      content: 'Hallo! Wie kann ich dir helfen?',
      shortcut: '/hello',
      category: 'quick',
    ),
    MessageTemplate(
      id: '6',
      title: 'Python Code',
      content: '```python\n\n```',
      shortcut: '/py',
      category: 'code',
    ),
    MessageTemplate(
      id: '7',
      title: 'JavaScript Code',
      content: '```javascript\n\n```',
      shortcut: '/js',
      category: 'code',
    ),
    MessageTemplate(
      id: '8',
      title: 'Dart Code',
      content: '```dart\n\n```',
      shortcut: '/dart',
      category: 'code',
    ),
    MessageTemplate(
      id: '9',
      title: 'URL kopieren',
      content: 'Hier ist der Link: ',
      shortcut: '/url',
      category: 'links',
    ),
    MessageTemplate(
      id: '10',
      title: 'Okay',
      content: 'Alles klar, verstanden! ✅',
      shortcut: '/ok',
      category: 'quick',
    ),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'shortcut': shortcut,
    'isCustom': isCustom,
    'category': category,
  };

  factory MessageTemplate.fromJson(Map<String, dynamic> json) => MessageTemplate(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    shortcut: json['shortcut'] as String?,
    isCustom: json['isCustom'] as bool? ?? false,
    category: json['category'] as String? ?? 'custom',
  );

  MessageTemplate copyWith({
    String? title,
    String? content,
    String? shortcut,
    String? category,
  }) {
    return MessageTemplate(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      shortcut: shortcut ?? this.shortcut,
      isCustom: isCustom,
      category: category ?? this.category,
    );
  }
}