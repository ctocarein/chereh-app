import 'dart:io';

import '../entities/evaluation_session.dart';
import '../entities/question.dart';

typedef StartResult = ({EvaluationSession session, Question firstQuestion});

typedef AdvanceResult = ({
  EvaluationSession session,
  Question? nextQuestion,
  bool isComplete,
  String? completionMessage,
  double progress,
});

abstract class EvaluationRepository {
  /// Démarre une nouvelle session d'évaluation.
  Future<StartResult> start();

  /// Récupère la session en cours (si existante).
  Future<({EvaluationSession session, Question? currentQuestion})?> getCurrent();

  /// Récupère l'état d'une session par son ID.
  Future<EvaluationSession> getState(String sessionId);

  /// Soumet une réponse et retourne la question suivante ou la fin.
  Future<AdvanceResult> advance({
    required String sessionId,
    required String questionId,
    required dynamic value,
  });

  /// Upload un fichier et retourne son ID.
  Future<String> uploadFile(File file, String mediaType);
}
