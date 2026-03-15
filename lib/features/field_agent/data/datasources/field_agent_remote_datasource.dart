import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/models/beneficiary_registration.dart';

final fieldAgentRemoteDatasourceProvider =
    Provider<FieldAgentRemoteDatasource>((ref) {
  return FieldAgentRemoteDatasource(ref.watch(apiClientProvider));
});

/// Datasource FieldAgent — POST /agent/beneficiaries
class FieldAgentRemoteDatasource {
  final Dio _dio;
  FieldAgentRemoteDatasource(this._dio);

  /// Scanne le QR d'un bénéficiaire (chereh://identity/{id}).
  /// Le lie à l'organisation de l'agent si nécessaire.
  Future<BeneficiaryRegistration> scanQr(String identityId) async {
    try {
      final res = await _dio.post(
        '/agent/qr-scan',
        data: {'identity_id': identityId},
      );
      final d = res.data as Map<String, dynamic>;
      return BeneficiaryRegistration(
        identityId: d['identity_id'] as String,
        phone: d['phone'] as String,
        // isNew = true si le bénéficiaire n'était pas encore lié à l'org de l'agent
        isNew: !(d['is_linked'] as bool? ?? true),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Crée ou retrouve un bénéficiaire par son numéro de téléphone.
  /// Retourne les données d'identité sans token.
  Future<BeneficiaryRegistration> registerBeneficiary(String phone) async {
    try {
      final res = await _dio.post(
        '/agent/beneficiaries',
        data: {'phone': phone},
      );
      return BeneficiaryRegistration.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
