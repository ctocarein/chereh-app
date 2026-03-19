import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/answer.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/question.dart';

final evaluationLocalDatasourceProvider =
    Provider<EvaluationLocalDatasource>((ref) {
  return EvaluationLocalDatasource();
});

/// Persistance de la session d'évaluation en cours (équivalent localStorage).
class EvaluationLocalDatasource {
  static const _key = 'evaluation_flow_v6';
  static const currentVersion = 6;

  Future<StoredFlowState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final state = StoredFlowState.fromJson(json);
      if (!state.isValid) {
        await clear();
        return null;
      }
      return state;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(StoredFlowState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Modèle de l'état persisté — mirror du StoredFlowState Next.js.
class StoredFlowState {
  final int version;
  final List<Answer> answers;
  final List<ChatMessage> messages;
  final List<Question> questionHistory;
  final bool isComplete;
  final String? sessionId;
  final String? sessionInternalId;
  final String? completionMessage;
  final String? sessionStatus;
  final String? terminationType;
  final String? terminationReason;

  const StoredFlowState({
    required this.version,
    required this.answers,
    required this.messages,
    required this.questionHistory,
    required this.isComplete,
    this.sessionId,
    this.sessionInternalId,
    this.completionMessage,
    this.sessionStatus,
    this.terminationType,
    this.terminationReason,
  });

  bool get isValid => version == EvaluationLocalDatasource.currentVersion;

  factory StoredFlowState.fromJson(Map<String, dynamic> json) =>
      StoredFlowState(
        version: json['version'] as int? ?? 0,
        answers: (json['answers'] as List? ?? [])
            .map((e) => Answer.fromJson(e as Map<String, dynamic>))
            .toList(),
        messages: (json['messages'] as List? ?? [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        questionHistory: (json['question_history'] as List? ?? [])
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        isComplete: json['is_complete'] as bool? ?? false,
        sessionId: json['session_id'] as String?,
        sessionInternalId: json['session_internal_id'] as String?,
        completionMessage: json['completion_message'] as String?,
        sessionStatus: json['session_status'] as String?,
        terminationType: json['termination_type'] as String?,
        terminationReason: json['termination_reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'answers': answers.map((a) => a.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'question_history': questionHistory.map((q) => q.toJson()).toList(),
        'is_complete': isComplete,
        if (sessionId != null) 'session_id': sessionId,
        if (sessionInternalId != null)
          'session_internal_id': sessionInternalId,
        if (completionMessage != null) 'completion_message': completionMessage,
        if (sessionStatus != null) 'session_status': sessionStatus,
        if (terminationType != null) 'termination_type': terminationType,
        if (terminationReason != null) 'termination_reason': terminationReason,
      };
}
