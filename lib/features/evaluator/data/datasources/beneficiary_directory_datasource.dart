import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/beneficiary_summary.dart';

final beneficiaryDirectoryDatasourceProvider =
    Provider<BeneficiaryDirectoryDatasource>((ref) {
  return BeneficiaryDirectoryDatasource(ref.watch(apiClientProvider));
});

/// Filtre sur l'état de la dernière évaluation.
enum DirectoryFilter {
  all,
  inProgress,
  completed,
  never;

  /// Valeur attendue par l'API. `null` pour « tous ».
  String? get query => switch (this) {
        DirectoryFilter.all => null,
        DirectoryFilter.inProgress => 'in_progress',
        DirectoryFilter.completed => 'completed',
        DirectoryFilter.never => 'never',
      };

  String get label => switch (this) {
        DirectoryFilter.all => 'Tous',
        DirectoryFilter.inProgress => 'En cours',
        DirectoryFilter.completed => 'Évalués',
        DirectoryFilter.never => 'Jamais évalués',
      };
}

/// Une page de l'annuaire.
class BeneficiaryDirectoryPage {
  final List<BeneficiarySummary> items;
  final int total;
  final int currentPage;
  final int lastPage;

  const BeneficiaryDirectoryPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;

  static const empty = BeneficiaryDirectoryPage(
    items: [],
    total: 0,
    currentPage: 1,
    lastPage: 1,
  );
}

/// Annuaire des bénéficiaires — GET /agent/beneficiaries
///
/// Servi à l'agent de terrain comme à l'ambassadeur : l'API borne d'elle-même
/// la liste aux organisations où l'appelant porte un rôle d'évaluateur.
class BeneficiaryDirectoryDatasource {
  final Dio _dio;
  BeneficiaryDirectoryDatasource(this._dio);

  Future<BeneficiaryDirectoryPage> fetch({
    String? search,
    DirectoryFilter filter = DirectoryFilter.all,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final trimmed = search?.trim();
      final res = await _dio.get(
        '/agent/beneficiaries',
        queryParameters: {
          if (trimmed != null && trimmed.isNotEmpty) 'search': trimmed,
          if (filter.query != null) 'status': filter.query,
          'page': page,
          'per_page': perPage,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final rows = (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BeneficiarySummary.fromJson)
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? const {};

      return BeneficiaryDirectoryPage(
        items: rows,
        total: (meta['total'] as num?)?.toInt() ?? rows.length,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
