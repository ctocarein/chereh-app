class EvaluationSession {
  final String sessionId;
  final String? sessionInternalId;
  final bool isComplete;
  final String? completionMessage;

  /// 'in_progress' | 'completed' | 'expired'
  final String? status;
  final String? terminationType;
  final String? terminationReason;

  const EvaluationSession({
    required this.sessionId,
    this.sessionInternalId,
    this.isComplete = false,
    this.completionMessage,
    this.status,
    this.terminationType,
    this.terminationReason,
  });

  EvaluationSession copyWith({
    String? sessionId,
    String? sessionInternalId,
    bool? isComplete,
    String? completionMessage,
    String? status,
    String? terminationType,
    String? terminationReason,
  }) =>
      EvaluationSession(
        sessionId: sessionId ?? this.sessionId,
        sessionInternalId: sessionInternalId ?? this.sessionInternalId,
        isComplete: isComplete ?? this.isComplete,
        completionMessage: completionMessage ?? this.completionMessage,
        status: status ?? this.status,
        terminationType: terminationType ?? this.terminationType,
        terminationReason: terminationReason ?? this.terminationReason,
      );

  factory EvaluationSession.fromJson(Map<String, dynamic> json) =>
      EvaluationSession(
        sessionId: json['public_id'] as String? ??
            json['session_id'] as String? ??
            json['id'].toString(),
        sessionInternalId: json['id']?.toString(),
        isComplete: json['is_complete'] as bool? ??
            json['status'] == 'completed',
        completionMessage: json['completion_message'] as String?,
        status: json['status'] as String?,
        terminationType: json['termination_type'] as String?,
        terminationReason: json['termination_reason'] as String?,
      );
}
