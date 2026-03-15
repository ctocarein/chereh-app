import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/referral_attribution.dart';

final referralAttributionDatasourceProvider =
    Provider<ReferralAttributionDatasource>((ref) {
  return ReferralAttributionDatasource(ref.watch(apiClientProvider));
});

class ReferralAttributionDatasource {
  final Dio _dio;
  ReferralAttributionDatasource(this._dio);

  /// POST /referral/claim
  /// Utilisé par les Priorités 1 (Install Referrer), 2 (deep link), 3 (presse-papiers).
  Future<ReferralAttribution?> claimByToken({
    required String clickToken,
    String? deviceModel,
  }) async {
    try {
      final res = await _dio.post(
        '/referral/claim',
        data: {
          'click_token':  clickToken,
          if (deviceModel != null) 'device_model': deviceModel,
        },
      );
      return ReferralAttribution.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 409 ||
          e.response?.statusCode == 410) {
        return null; // Token inconnu, déjà utilisé ou expiré
      }
      throw ApiException.fromDio(e);
    }
  }

  /// POST /referral/claim/fingerprint
  /// Priorité 4 : fallback empreinte.
  Future<ReferralAttribution?> claimByFingerprint({
    required String deviceModel,
    String? osVersion,
  }) async {
    try {
      final res = await _dio.post(
        '/referral/claim/fingerprint',
        data: {
          'device_model':          deviceModel,
          if (osVersion != null) 'os_version': osVersion,
        },
      );
      return ReferralAttribution.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 429) {
        return null; // Pas de match ou limite atteinte
      }
      throw ApiException.fromDio(e);
    }
  }
}
