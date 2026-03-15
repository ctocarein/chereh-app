import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';

// ============================================================================
// Modèle rapport — couvre à la fois la liste et le détail
// ============================================================================

class ReportSummary {
  final int id;
  final String? reportCode;
  final String? title;
  final String riskLevel;   // 'low' | 'medium' | 'high' | 'very_high'
  final double? score;
  final double? maxScore;
  final String? recommendation;
  final List<String> specialties;
  final List<dynamic> summary; // tableau libre retourné par l'API
  final DateTime createdAt;

  const ReportSummary({
    required this.id,
    this.reportCode,
    this.title,
    required this.riskLevel,
    this.score,
    this.maxScore,
    this.recommendation,
    this.specialties = const [],
    this.summary = const [],
    required this.createdAt,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      id: json['id'] as int,
      reportCode: json['report_code'] as String?,
      title: json['title'] as String?,
      riskLevel: (json['risk_level'] as String?) ?? 'low',
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      recommendation: json['recommendation'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: (json['summary'] as List<dynamic>?) ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ============================================================================
// Datasource — GET /reports  &  GET /reports/{id}
// ============================================================================

final reportRemoteDatasourceProvider = Provider<ReportRemoteDatasource>((ref) {
  return ReportRemoteDatasource(ref.watch(apiClientProvider));
});

class ReportRemoteDatasource {
  final Dio _dio;
  ReportRemoteDatasource(this._dio);

  /// Retourne tous les rapports de l'utilisateur connecté, triés par date desc.
  Future<List<ReportSummary>> getReports() async {
    try {
      final res = await _dio.get('/reports');
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Retourne le détail d'un rapport par son id.
  Future<ReportSummary> getReportById(int id) async {
    try {
      final res = await _dio.get('/reports/$id');
      final data = res.data as Map<String, dynamic>;
      return ReportSummary.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
