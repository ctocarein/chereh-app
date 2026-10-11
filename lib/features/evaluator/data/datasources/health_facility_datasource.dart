import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/health_facility.dart';

final healthFacilityDatasourceProvider =
    Provider<HealthFacilityDatasource>((ref) {
  return HealthFacilityDatasource(ref.watch(apiClientProvider));
});

/// Filtre sur la présence d'un mammographe.
enum MammographyFilter {
  all,
  available,
  unavailable;

  /// Valeur attendue par l'API. `null` pour « tous ».
  int? get query => switch (this) {
        MammographyFilter.all => null,
        MammographyFilter.available => 1,
        MammographyFilter.unavailable => 0,
      };

  String get label => switch (this) {
        MammographyFilter.all => 'Tous',
        MammographyFilter.available => 'Avec mammographe',
        MammographyFilter.unavailable => 'Sans mammographe',
      };
}

/// Les établissements correspondant à un filtre et une recherche.
///
/// Le couple sert de clé : changer l'un relance la requête, revenir à une
/// combinaison déjà vue la resert tant qu'elle est écoutée.
final healthFacilitiesProvider = FutureProvider.autoDispose
    .family<List<HealthFacility>, ({MammographyFilter filter, String search})>(
  (ref, query) => ref
      .watch(healthFacilityDatasourceProvider)
      .fetch(filter: query.filter, search: query.search),
);

/// Établissements de santé — GET /health-facilities
class HealthFacilityDatasource {
  final Dio _dio;
  HealthFacilityDatasource(this._dio);

  /// Une seule page large : le référentiel tient en quelques dizaines de
  /// lignes par zone. À paginer s'il dépasse la centaine.
  Future<List<HealthFacility>> fetch({
    MammographyFilter filter = MammographyFilter.all,
    String? search,
  }) async {
    try {
      final trimmed = search?.trim();
      final res = await _dio.get(
        '/health-facilities',
        queryParameters: {
          'mammography': ?filter.query,
          if (trimmed != null && trimmed.isNotEmpty) 'search': trimmed,
          'per_page': 100,
        },
      );

      final data = res.data as Map<String, dynamic>;
      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HealthFacility.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
