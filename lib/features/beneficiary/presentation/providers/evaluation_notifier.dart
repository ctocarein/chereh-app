import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/services/beneficiary_preference.dart';
import '../../data/datasources/evaluation_local_datasource.dart';
import '../../data/datasources/evaluation_remote_datasource.dart';
import '../../domain/entities/answer.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/evaluation_session.dart';
import '../../domain/entities/question.dart';
import 'evaluation_state.dart';

final evaluationNotifierProvider =
    NotifierProvider<EvaluationNotifier, EvaluationState>(
  EvaluationNotifier.new,
);

class EvaluationNotifier extends Notifier<EvaluationState> {
  /// Renseigné uniquement pour une évaluation assistée (FieldAgent → Bénéficiaire).
  String? _subjectId;

  @override
  EvaluationState build() => const EvaluationIdle();

  // ---------------------------------------------------------------------------
  // Cycle de vie
  // ---------------------------------------------------------------------------

  /// Point d'entrée : appelé au montage de [EvaluationScreen].
  /// [subjectId] : UUID du bénéficiaire ciblé (éval. assistée par un FieldAgent).
  Future<void> initialize({String? subjectId}) async {
    _subjectId = subjectId;
    state = const EvaluationLoading();
    try {
      final local = ref.read(evaluationLocalDatasourceProvider);
      // En mode assisté, on ne reprend pas la session locale (elle appartient à l'agent)
      final stored = subjectId != null ? null : await local.load();

      // Tentative de reprise d'une session existante
      if (stored != null &&
          stored.isValid &&
          !stored.isComplete &&
          stored.questionHistory.isNotEmpty) {
        // getCurrent() retourne la session ET la question courante du serveur
        try {
          final remote = ref.read(evaluationRemoteDatasourceProvider);
          final current = await remote.getCurrent();
          if (current != null && current.session.status == 'in_progress') {
            await _markStarted();
            final serverQ = current.currentQuestion;
            List<Question> history = stored.questionHistory;
            List<ChatMessage> messages = stored.messages;
            Question currentQ;

            if (serverQ != null &&
                !history.any((q) => q.id == serverQ.id)) {
              // Le serveur a avancé au-delà du local → synchroniser
              history = [...history, serverQ];
              messages = [...messages, _makeBotMessage(serverQ.text)];
              currentQ = serverQ;
            } else {
              currentQ = serverQ ?? history.last;
            }

            final active = EvaluationActive(
              session: current.session,
              messages: _withSingleEditableLatestUserMessage(messages),
              answers: stored.answers,
              questionHistory: history,
              currentQuestion: currentQ,
              progress: _computeProgress(
                  stored.answers.length, currentQ.totalSteps),
            );
            state = active;
            await _persist(active);
            return;
          }
        } catch (_) {}

        // Session invalide → on repart de zéro
        await local.clear();
      }

      await _startNew();
    } catch (e) {
      state = EvaluationError(e.toString());
    }
  }

  Future<void> _startNew() async {
    final remote = ref.read(evaluationRemoteDatasourceProvider);
    try {
      final result = await remote.start(subjectId: _subjectId);
      await _markStarted();
      final firstMsg = _makeBotMessage(result.firstQuestion.text);
      final active = EvaluationActive(
        session: result.session,
        messages: [firstMsg],
        answers: [],
        questionHistory: [result.firstQuestion],
        currentQuestion: result.firstQuestion,
        progress: 0,
      );
      state = active;
      await _persist(active);
    } on ApiException catch (e) {
      if (e.errorCode == 'SESSION_IN_PROGRESS') {
        // Le serveur signale une session active — on la reprend via /current
        final current = await remote.getCurrent();
        if (current != null && current.currentQuestion != null) {
          await _markStarted();
          final firstMsg = _makeBotMessage(current.currentQuestion!.text);
          final active = EvaluationActive(
            session: current.session,
            messages: [firstMsg],
            answers: const [],
            questionHistory: [current.currentQuestion!],
            currentQuestion: current.currentQuestion!,
            progress: 0,
          );
          state = active;
          await _persist(active);
          return;
        }
      }
      if (e.errorCode == 'ALREADY_COMPLETED') {
        // Évaluation déjà terminée → afficher l'écran de fin
        state = const EvaluationComplete(
          session: EvaluationSession(
            sessionId: '',
            isComplete: true,
            status: 'completed',
          ),
          messages: [],
          completionMessage: 'Votre évaluation est déjà complétée.',
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> _markStarted() async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is AuthStateAuthenticated) {
      await BeneficiaryPreference.markEvaluationStarted(authState.user.id);
    }
  }

  // ---------------------------------------------------------------------------
  // Répondre à une question
  // ---------------------------------------------------------------------------

  /// Soumet la réponse de l'utilisateur.
  /// Si [file] est fourni, l'upload est effectué avant d'avancer.
  Future<void> answer(dynamic value, {File? file}) async {
    if (state is! EvaluationActive) return;
    final current = state as EvaluationActive;

    // Désactiver l'input
    state = current.copyWith(isSubmitting: true);

    try {
      dynamic payload = value;

      // Upload fichier si nécessaire
      if (file != null) {
        final remote = ref.read(evaluationRemoteDatasourceProvider);
        final fileId = await remote.uploadFile(
          file,
          current.currentQuestion.type.name,
        );
        payload = fileId;
      }

      // Bulle utilisateur
      final userMsg = _makeUserMessage(
        _formatValue(value, current.currentQuestion),
        stepIndex: current.questionHistory.length - 1,
      );

      final newAnswers = [
        ...current.answers,
        Answer(
          questionId: current.currentQuestion.id,
          value: payload,
          timestamp: DateTime.now(),
        ),
      ];

      // Indicateur de frappe
      final typingId = _genId();
      final typingMsg = ChatMessage(
        id: typingId,
        role: ChatRole.bot,
        isTyping: true,
        timestamp: DateTime.now(),
      );

      state = current.copyWith(
        messages: _withSingleEditableLatestUserMessage([
          ...current.messages,
          userMsg,
          typingMsg,
        ]),
        answers: newAnswers,
        isTyping: true,
        isSubmitting: true,
      );

      // Appel API
      final remote = ref.read(evaluationRemoteDatasourceProvider);
      final isAck = current.currentQuestion.isAcknowledgement;
      final result = await remote.advance(
        sessionId: current.session.sessionId,
        questionId: current.currentQuestion.id,
        value: isAck ? null : payload,
        isSkipped: isAck,
      );

      final active = state as EvaluationActive;
      // Retirer l'indicateur de frappe
      final msgs =
          active.messages.where((m) => m.id != typingId).toList();

      if (result.isComplete) {
        final completionMsg = _makeBotMessage(
          result.completionMessage ?? 'Merci ! Votre évaluation est terminée.',
        );
        final updatedSession = result.session.copyWith(
          isComplete: true,
          completionMessage: result.completionMessage,
        );

        await _persistComplete(
          session: updatedSession,
          messages: [...msgs, completionMsg],
          answers: newAnswers,
          questionHistory: active.questionHistory,
          completionMessage: result.completionMessage,
        );

        state = EvaluationComplete(
          session: updatedSession,
          messages: [...msgs, completionMsg],
          completionMessage: result.completionMessage,
        );
      } else {
        final next = result.nextQuestion!;
        final botMsg = _makeBotMessage(next.text);
        final newHistory = [...active.questionHistory, next];

        final newActive = EvaluationActive(
          session: result.session,
          messages: _withSingleEditableLatestUserMessage([...msgs, botMsg]),
          answers: newAnswers,
          questionHistory: newHistory,
          currentQuestion: next,
          progress: result.progress,
          isTyping: false,
          isSubmitting: false,
        );

        state = newActive;
        await _persist(newActive);
      }
    } catch (e) {
      // Retirer le spinner en cas d'erreur
      if (state is EvaluationActive) {
        final active = state as EvaluationActive;
        state = active.copyWith(
          messages: active.messages
              .where((m) => !m.isTyping)
              .toList(),
          isTyping: false,
          isSubmitting: false,
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Édition — rejouer depuis une réponse antérieure
  // ---------------------------------------------------------------------------

  void editStep(int stepIndex) {
    if (state is! EvaluationActive) return;
    final current = state as EvaluationActive;
    if (stepIndex >= current.questionHistory.length) return;

    final newHistory = current.questionHistory.sublist(0, stepIndex + 1);
    final newAnswers = current.answers.sublist(0, stepIndex);

    // Messages : on garde (stepIndex * 2 + 1) — bot+user alternés
    final keepCount = min(stepIndex * 2 + 1, current.messages.length);
    final newMessages = _withSingleEditableLatestUserMessage(
      current.messages.sublist(0, keepCount),
    );

    state = current.copyWith(
      questionHistory: newHistory,
      answers: newAnswers,
      messages: newMessages,
      currentQuestion: newHistory.last,
      progress: _computeProgress(newAnswers.length, newHistory.last.totalSteps),
      isTyping: false,
      isSubmitting: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _genId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  ChatMessage _makeBotMessage(String text) => ChatMessage(
        id: _genId(),
        role: ChatRole.bot,
        text: text,
        timestamp: DateTime.now(),
      );

  ChatMessage _makeUserMessage(String text, {int? stepIndex}) => ChatMessage(
        id: _genId(),
        role: ChatRole.user,
        text: text,
        timestamp: DateTime.now(),
        interactive: stepIndex != null,
        relatedStepIndex: stepIndex,
      );

  List<ChatMessage> _withSingleEditableLatestUserMessage(
    List<ChatMessage> messages,
  ) {
    int latestUserMessageIndex = -1;
    int userStepIndex = -1;
    final stepIndices = List<int?>.filled(messages.length, null);

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.role != ChatRole.user || message.isTyping) continue;

      userStepIndex += 1;
      stepIndices[i] = userStepIndex;
      latestUserMessageIndex = i;
    }

    if (latestUserMessageIndex == -1) {
      return messages;
    }

    return List<ChatMessage>.generate(messages.length, (index) {
      final message = messages[index];
      final stepIndex = stepIndices[index];

      if (message.role != ChatRole.user || message.isTyping || stepIndex == null) {
        if (!message.interactive && message.relatedStepIndex == null) {
          return message;
        }
        return message.copyWith(interactive: false, relatedStepIndex: null);
      }

      return message.copyWith(
        interactive: index == latestUserMessageIndex,
        relatedStepIndex: stepIndex,
      );
    });
  }

  /// Formate une valeur brute en texte lisible pour la bulle utilisateur.
  String _formatValue(dynamic value, Question question) {
    if (value == null) return '–';
    if (value is List) return value.join(', ');
    if (value is bool) return value ? 'Oui' : 'Non';
    if (question.type == QuestionType.rating) return '$value ★';
    return value.toString();
  }

  double _computeProgress(int answered, int? total) {
    if (total == null || total == 0) return 0;
    return (answered / total).clamp(0.0, 1.0);
  }

  Future<void> _persist(EvaluationActive active) async {
    final local = ref.read(evaluationLocalDatasourceProvider);
    await local.save(StoredFlowState(
      version: EvaluationLocalDatasource.currentVersion,
      answers: active.answers,
      messages: active.messages,
      questionHistory: active.questionHistory,
      isComplete: false,
      sessionId: active.session.sessionId,
      sessionInternalId: active.session.sessionInternalId,
      sessionStatus: active.session.status,
      terminationType: active.session.terminationType,
      terminationReason: active.session.terminationReason,
    ));
  }

  Future<void> _persistComplete({
    required EvaluationSession session,
    required List<ChatMessage> messages,
    required List<Answer> answers,
    required List<Question> questionHistory,
    String? completionMessage,
  }) async {
    final local = ref.read(evaluationLocalDatasourceProvider);
    await local.save(StoredFlowState(
      version: EvaluationLocalDatasource.currentVersion,
      answers: answers,
      messages: messages,
      questionHistory: questionHistory,
      isComplete: true,
      sessionId: session.sessionId,
      sessionInternalId: session.sessionInternalId,
      completionMessage: completionMessage,
      sessionStatus: session.status,
      terminationType: session.terminationType,
      terminationReason: session.terminationReason,
    ));
  }
}
