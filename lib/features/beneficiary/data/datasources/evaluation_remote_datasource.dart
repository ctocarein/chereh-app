import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/entities/evaluation_session.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/evaluation_repository.dart';

final evaluationRemoteDatasourceProvider =
    Provider<EvaluationRemoteDatasource>((ref) {
  return EvaluationRemoteDatasource(ref.watch(apiClientProvider));
});

class EvaluationRemoteDatasource {
  final Dio _dio;
  EvaluationRemoteDatasource(this._dio);

  /// POST /evaluations/start
  /// [subjectId] : UUID du bénéficiaire — uniquement pour un FieldAgent (éval. assistée)
  Future<StartResult> start({
    String type = 'complete',
    List<String>? blocKeys,
    String? subjectId,
  }) async {
    try {
      final res = await _dio.post(
        '/evaluations/start',
        data: {
          'type': type,
          'bloc_keys': ?blocKeys,
          'subject_id': ?subjectId,
        },
      );
      return _parseStartResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /evaluations/current
  Future<({EvaluationSession session, Question? currentQuestion})?> getCurrent() async {
    try {
      final res = await _dio.get('/evaluations/current');
      if (res.data == null) return null;
      final data = res.data as Map<String, dynamic>;
      final sessionData = data['session'] as Map<String, dynamic>? ?? data;
      final questionData = data['question'] as Map<String, dynamic>?;
      return (
        session: EvaluationSession.fromJson(sessionData),
        currentQuestion: questionData != null
            ? Question.fromJson(questionData)
            : null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  /// GET /evaluations/{id}/state
  Future<EvaluationSession> getState(String sessionId) async {
    try {
      final res = await _dio.get('/evaluations/$sessionId/state');
      final data = res.data as Map<String, dynamic>;
      final sessionData = data['session'] as Map<String, dynamic>? ?? data;
      return EvaluationSession.fromJson(sessionData);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /evaluations/{id}/advance
  Future<AdvanceResult> advance({
    required String sessionId,
    required String questionId,
    required dynamic value,
    bool isSkipped = false,
  }) async {
    try {
      final res = await _dio.post(
        '/evaluations/$sessionId/advance',
        data: {
          'dynamic_question_template_id': int.tryParse(questionId) ?? questionId,
          if (!isSkipped) 'value': value,
          if (isSkipped) 'is_skipped': true,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final sessionData = data['session'] as Map<String, dynamic>?;
      final session = EvaluationSession.fromJson(sessionData ?? data);
      final sessionStatus = sessionData?['status'] as String?;
      final isComplete =
          sessionStatus == 'completed' || sessionStatus == 'cancelled';
      final questionData = data['question'] as Map<String, dynamic>?;
      return (
        session: session,
        nextQuestion: !isComplete && questionData != null
            ? Question.fromJson(questionData)
            : null,
        isComplete: isComplete,
        completionMessage: data['message'] as String?,
        progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /uploads
  Future<String> uploadFile(File file, String mediaType) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'type': mediaType,
      });
      final res = await _dio.post('/uploads', data: form);
      return (res.data as Map<String, dynamic>)['file_id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  StartResult _parseStartResult(Map<String, dynamic> data) {
    final sessionData =
        data['session'] as Map<String, dynamic>? ?? data;
    final questionData = data['question'] as Map<String, dynamic>? ??
        data['first_question'] as Map<String, dynamic>?;
    return (
      session: EvaluationSession.fromJson(sessionData),
      firstQuestion: questionData != null
          ? Question.fromJson(questionData)
          : const Question(id: '0', type: QuestionType.info, text: ''),
    );
  }
}
