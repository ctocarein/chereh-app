class Answer {
  final String questionId;
  final dynamic value;
  final DateTime timestamp;

  const Answer({
    required this.questionId,
    required this.value,
    required this.timestamp,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        questionId: json['question_id'] as String,
        value: json['value'],
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
      };
}
