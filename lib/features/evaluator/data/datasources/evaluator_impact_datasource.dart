import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/evaluator_impact.dart';

final evaluatorImpactDatasourceProvider =
    Provider<EvaluatorImpactDatasource>((ref) {
  return EvaluatorImpactDatasource(ref.watch(apiClientProvider));
});

/// L'impact de l'évaluateur connecté — GET /agent/impact
///
/// Sert l'ambassadrice comme l'agent de terrain : l'API borne d'elle-même les
/// chiffres au travail de l'appelant.
final evaluatorImpactProvider = FutureProvider<EvaluatorImpact>((ref) {
  return ref.watch(evaluatorImpactDatasourceProvider).fetch();
});

class EvaluatorImpactDatasource {
  final Dio _dio;
  EvaluatorImpactDatasource(this._dio);

  Future<EvaluatorImpact> fetch() async {
    try {
      final res = await _dio.get('/agent/impact');
      return EvaluatorImpact.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
