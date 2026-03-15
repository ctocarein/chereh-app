enum ChatRole { bot, user }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String? text;
  final bool isTyping;
  final DateTime timestamp;

  /// 'default' | 'soft' | 'accent'
  final String variant;

  /// Rend la bulle interactive (édition d'une réponse antérieure).
  final bool interactive;

  /// Index dans [questionHistory] pour rejouer depuis ce point.
  final int? relatedStepIndex;

  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.isTyping = false,
    required this.timestamp,
    this.variant = 'default',
    this.interactive = false,
    this.relatedStepIndex,
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? text,
    bool? isTyping,
    DateTime? timestamp,
    String? variant,
    bool? interactive,
    int? relatedStepIndex,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        text: text ?? this.text,
        isTyping: isTyping ?? this.isTyping,
        timestamp: timestamp ?? this.timestamp,
        variant: variant ?? this.variant,
        interactive: interactive ?? this.interactive,
        relatedStepIndex: relatedStepIndex ?? this.relatedStepIndex,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] == 'bot' ? ChatRole.bot : ChatRole.user,
        text: json['text'] as String?,
        isTyping: json['is_typing'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        variant: json['variant'] as String? ?? 'default',
        interactive: json['interactive'] as bool? ?? false,
        relatedStepIndex: json['related_step_index'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        if (text != null) 'text': text,
        'is_typing': isTyping,
        'timestamp': timestamp.toIso8601String(),
        'variant': variant,
        'interactive': interactive,
        if (relatedStepIndex != null) 'related_step_index': relatedStepIndex,
      };
}
