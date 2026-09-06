import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

// ---------------------------------------------------------------------------
// Thematic blocs
// ---------------------------------------------------------------------------

enum ThematicIntention {
  assessment,
  screening,
  monitoring,
  preparation,
  followUp,
  education,
  triage,
  sharedDecision,
  crisis;

  static ThematicIntention fromString(String? value) => switch (value) {
        'assessment'      => ThematicIntention.assessment,
        'screening'       => ThematicIntention.screening,
        'monitoring'      => ThematicIntention.monitoring,
        'preparation'     => ThematicIntention.preparation,
        'follow_up'       => ThematicIntention.followUp,
        'education'       => ThematicIntention.education,
        'triage'          => ThematicIntention.triage,
        'shared_decision' => ThematicIntention.sharedDecision,
        'crisis'          => ThematicIntention.crisis,
        _                 => ThematicIntention.assessment,
      };
}

class ThematicBlocDto {
  final String key;
  final String title;
  final String? description;
  final String? icon;
  final String? color;
  final ThematicIntention intention;
  final int priority;

  const ThematicBlocDto({
    required this.key,
    required this.title,
    this.description,
    this.icon,
    this.color,
    this.intention = ThematicIntention.assessment,
    this.priority = 0,
  });

  factory ThematicBlocDto.fromJson(Map<String, dynamic> json) =>
      ThematicBlocDto(
        key:       json['key'] as String,
        title:     json['title'] as String,
        description: json['description'] as String?,
        icon:      json['icon'] as String?,
        color:     json['color'] as String?,
        intention: ThematicIntention.fromString(json['intention'] as String?),
        priority:  (json['priority'] as num?)?.toInt() ?? 0,
      );

  IconData get iconData => switch (icon) {
        'water_drop'        => Icons.water_drop_outlined,
        'favorite'          => Icons.favorite_border_rounded,
        'medical_services'  => Icons.medical_services_outlined,
        'calendar_month'    => Icons.calendar_month_outlined,
        'self_improvement'  => Icons.self_improvement_outlined,
        'vaccines'          => Icons.vaccines_outlined,
        'monitor_heart'     => Icons.monitor_heart_outlined,
        'nightlight'        => Icons.nightlight_outlined,
        'psychology'        => Icons.psychology_outlined,
        'health_and_safety' => Icons.health_and_safety_outlined,
        'heart'             => Icons.favorite_border_rounded,
        'shield'            => Icons.shield_outlined,
        'user'              => Icons.person_outline_rounded,
        'users'             => Icons.group_outlined,
        'activity'          => Icons.show_chart_rounded,
        'clipboard'         => Icons.assignment_outlined,
        'calendar'          => Icons.calendar_month_outlined,
        'search'            => Icons.search_rounded,
        _                   => Icons.chat_bubble_outline_rounded,
      };
}

final thematicBlocsProvider = FutureProvider<List<ThematicBlocDto>>((ref) {
  return ref.read(evaluationRemoteDatasourceProvider).fetchThematicBlocs();
});

class EvaluationRemoteDatasource {
  final Dio _dio;
  EvaluationRemoteDatasource(this._dio);

  /// POST /evaluations/start
  ///
  /// [subjectId] : UUID d'une bénéficiaire déjà enregistrée (évaluation assistée).
  /// [newSubject] : crée la fiche en même temps que la session, pour quelqu'un
  /// qui n'est pas encore enregistré. Son numéro et sa commune sont ensuite
  /// collectés par le questionnaire. Les deux sont exclusifs.
  Future<StartResult> start({
    String type = 'complete',
    List<String>? blocKeys,
    String? subjectId,
    bool newSubject = false,
  }) async {
    try {
      final res = await _dio.post(
        '/evaluations/start',
        data: {
          'type': type,
          'bloc_keys': ?blocKeys,
          'subject_id': ?subjectId,
          if (newSubject) 'new_subject': true,
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

  /// GET /thematic-blocs
  Future<List<ThematicBlocDto>> fetchThematicBlocs() async {
    try {
      final res = await _dio.get('/thematic-blocs');
      final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(ThematicBlocDto.fromJson)
          .toList();
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
