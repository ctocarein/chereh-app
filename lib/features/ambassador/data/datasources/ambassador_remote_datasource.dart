import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/ambassador_models.dart';

final ambassadorRemoteDatasourceProvider =
    Provider<AmbassadorRemoteDatasource>((ref) {
  return AmbassadorRemoteDatasource(ref.watch(apiClientProvider));
});

class AmbassadorRemoteDatasource {
  final Dio _dio;
  AmbassadorRemoteDatasource(this._dio);

  /// GET /ambassador/metrics
  Future<AmbassadorMetrics> getMetrics() async {
    try {
      final res = await _dio.get('/ambassador/metrics');
      return AmbassadorMetrics.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /ambassador/referrals
  Future<List<ReferralModel>> getReferrals() async {
    try {
      final res = await _dio.get('/ambassador/referrals');
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list
          .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /ambassador/referrals — génère ou réutilise un lien de parrainage.
  Future<GeneratedReferral> generateReferral({String? channel}) async {
    try {
      final res = await _dio.post(
        '/ambassador/referrals',
        data: {'channel': channel ?? 'other'},
      );
      final data = res.data as Map<String, dynamic>;
      return GeneratedReferral(
        referral: ReferralModel.fromJson(data['data'] as Map<String, dynamic>),
        url: data['url'] as String,
        reused: data['reused'] as bool? ?? false,
        remainingWeekly: data['remaining_weekly'] as int?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /ambassador/referrals/{id}/revoke
  Future<void> revokeReferral(String referralId) async {
    try {
      await _dio.post('/ambassador/referrals/$referralId/revoke');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
