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
  /// Renseigné uniquement pour une évaluation assistée (évaluateur → bénéficiaire).
  String? _subjectId;

  /// Vrai quand l'évaluateur ouvre une évaluation pour une personne pas encore
  /// enregistrée : le serveur crée la fiche au démarrage.
  bool _newSubject = false;

  @override
  EvaluationState build() => const EvaluationIdle();

  // ---------------------------------------------------------------------------
  // Cycle de vie
  // ---------------------------------------------------------------------------

  /// Point d'entrée : appelé au montage de [EvaluationScreen].
  /// [subjectId] : UUID de la bénéficiaire ciblée (évaluation assistée).
  /// [newSubject] : ouvre une évaluation pour une personne pas encore enregistrée.
  Future<void> initialize({String? subjectId, bool newSubject = false}) async {
    _subjectId = subjectId;
    _newSubject = newSubject;
    state = const EvaluationLoading();
    try {
      // En mode assisté, la reprise passe par le serveur et non par l'état
      // local, qui appartient à l'évaluateur et non à la personne qu'il évalue.
      // Sans cette étape, rouvrir l'écran après une coupure créerait une
      // seconde fiche au lieu de reprendre la visite commencée.
      if (subjectId != null || newSubject) {
        if (await _resumeAssisted()) return;
        await _startNew();
        return;
      }

      final local = ref.read(evaluationLocalDatasourceProvider);
      final stored = await local.load();

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

  /// Démarre une nouvelle évaluation thématique pour le bloc [blocKey].
  /// [blocLabel] et [blocIntention] sont propagés dans l'état pour le titre et les suggestions.
  /// Nettoie l'état local avant de démarrer.
  Future<void> startThematic(
    String blocKey, {
    String? blocLabel,
    ThematicIntention? blocIntention,
  }) async {
    state = const EvaluationLoading();
    await ref.read(evaluationLocalDatasourceProvider).clear();
    final remote = ref.read(evaluationRemoteDatasourceProvider);
    try {
      final result = await remote.start(type: 'thematic', blocKeys: [blocKey]);
      await _markStarted();
      final firstMsg = _makeBotMessage(result.firstQuestion.text);
      final active = EvaluationActive(
        session: result.session,
        messages: [firstMsg],
        answers: [],
        questionHistory: [result.firstQuestion],
        currentQuestion: result.firstQuestion,
        progress: 0,
        blocKey: blocKey,
        blocLabel: blocLabel,
        blocIntention: blocIntention,
      );
      state = active;
      await _persist(active);
    } on ApiException catch (e) {
      state = EvaluationError(e.message);
    } catch (e) {
      state = EvaluationError(e.toString());
    }
  }

  Future<void> _startNew() async {
    final remote = ref.read(evaluationRemoteDatasourceProvider);
    try {
      final result = await remote.start(
        subjectId: _subjectId,
        newSubject: _newSubject,
      );
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
        // Évaluation déjà terminée → afficher les suggestions thématiques
        state = const EvaluationComplete(
          session: EvaluationSession(
            sessionId: '',
            isComplete: true,
            status: 'completed',
            terminationType: 'already_completed',
          ),
          messages: [],
          completionMessage: 'Votre évaluation est terminée. Choisissez un sujet pour continuer la discussion.',
        );
        return;
      }
      rethrow;
    }
  }

  /// Cherche une visite déjà ouverte pour cet évaluateur et la reprend.
  /// Retourne vrai si l'état a été posé, faux s'il faut en démarrer une.
  Future<bool> _resumeAssisted() async {
    try {
      final remote = ref.read(evaluationRemoteDatasourceProvider);
      final current = await remote.getCurrent(subjectId: _subjectId);

      if (current == null ||
          current.session.status != 'in_progress' ||
          current.currentQuestion == null) {
        return false;
      }

      await _markStarted();
      final question = current.currentQuestion!;
      final active = EvaluationActive(
        session: current.session,
        messages: [_makeBotMessage(question.text)],
        answers: const [],
        questionHistory: [question],
        currentQuestion: question,
        progress: 0,
      );
      state = active;
      await _persist(active);
      return true;
    } catch (_) {
      // Réseau indisponible ou session inaccessible : on laisse le démarrage
      // trancher, il remontera une erreur exploitable.
      return false;
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
      final isSkipped = isAck ||
          (payload == null && current.currentQuestion.required == false);
      final result = await remote.advance(
        sessionId: current.session.sessionId,
        questionId: current.currentQuestion.id,
        value: isSkipped ? null : payload,
        isSkipped: isSkipped,
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
          blocKey: active.blocKey,
          blocLabel: active.blocLabel,
        );

        // Mémoriser le thème comme complété pour l'indicateur visuel
        if (active.blocKey != null) {
          final authState = ref.read(authNotifierProvider).valueOrNull;
          if (authState is AuthStateAuthenticated) {
            await BeneficiaryPreference.markThemeCompleted(
              authState.user.id,
              active.blocKey!,
            );
          }
        }

        state = EvaluationComplete(
          session: updatedSession,
          messages: [...msgs, completionMsg],
          completionMessage: result.completionMessage,
          blocKey: current.blocKey,
          blocLabel: current.blocLabel,
          blocIntention: current.blocIntention,
        );
      } else {
        final next = result.nextQuestion!;
        final botMsg = _makeBotMessage(next.text);
        final newHistory = [...active.questionHistory, next];

        final newActive = active.copyWith(
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
    if (question.isAcknowledgement) return 'Continuer';
    if (value is List) {
      return value
          .map((v) => question.labelForValue(v.toString()))
          .join(', ');
    }
    if (value is bool) return value ? 'Oui' : 'Non';
    if (question.type == QuestionType.selectOne ||
        question.type == QuestionType.radio) {
      return question.labelForValue(value.toString());
    }
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
      blocKey: active.blocKey,
      blocLabel: active.blocLabel,
    ));
  }

  Future<void> _persistComplete({
    required EvaluationSession session,
    required List<ChatMessage> messages,
    required List<Answer> answers,
    required List<Question> questionHistory,
    String? completionMessage,
    String? blocKey,
    String? blocLabel,
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
      blocKey: blocKey,
      blocLabel: blocLabel,
    ));
  }
}
