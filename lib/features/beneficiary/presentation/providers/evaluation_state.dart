import '../../domain/entities/answer.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/evaluation_session.dart';
import '../../domain/entities/question.dart';

sealed class EvaluationState {
  const EvaluationState();
}

final class EvaluationIdle extends EvaluationState {
  const EvaluationIdle();
}

final class EvaluationLoading extends EvaluationState {
  const EvaluationLoading();
}

final class EvaluationActive extends EvaluationState {
  final EvaluationSession session;
  final List<ChatMessage> messages;
  final List<Answer> answers;

  /// Historique des questions vues — permet la navigation arrière.
  final List<Question> questionHistory;

  final Question currentQuestion;
  final double progress;

  /// Le bot est en train de "taper".
  final bool isTyping;

  /// Une réponse est en cours d'envoi (input désactivé).
  final bool isSubmitting;

  const EvaluationActive({
    required this.session,
    required this.messages,
    required this.answers,
    required this.questionHistory,
    required this.currentQuestion,
    required this.progress,
    this.isTyping = false,
    this.isSubmitting = false,
  });

  EvaluationActive copyWith({
    EvaluationSession? session,
    List<ChatMessage>? messages,
    List<Answer>? answers,
    List<Question>? questionHistory,
    Question? currentQuestion,
    double? progress,
    bool? isTyping,
    bool? isSubmitting,
  }) =>
      EvaluationActive(
        session: session ?? this.session,
        messages: messages ?? this.messages,
        answers: answers ?? this.answers,
        questionHistory: questionHistory ?? this.questionHistory,
        currentQuestion: currentQuestion ?? this.currentQuestion,
        progress: progress ?? this.progress,
        isTyping: isTyping ?? this.isTyping,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

final class EvaluationComplete extends EvaluationState {
  final EvaluationSession session;
  final List<ChatMessage> messages;
  final String? completionMessage;

  const EvaluationComplete({
    required this.session,
    required this.messages,
    this.completionMessage,
  });
}

final class EvaluationError extends EvaluationState {
  final String message;
  const EvaluationError(this.message);
}
