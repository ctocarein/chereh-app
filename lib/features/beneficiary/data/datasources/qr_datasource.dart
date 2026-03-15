import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';

// ============================================================================
// Modèle résultat du scan QR organisation
// ============================================================================

class QrScanOrganization {
  final String id;
  final String name;
  final String? type;
  final String? city;

  const QrScanOrganization({
    required this.id,
    required this.name,
    this.type,
    this.city,
  });

  factory QrScanOrganization.fromJson(Map<String, dynamic> json) {
    return QrScanOrganization(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
      city: json['city'] as String?,
    );
  }
}

class QrScanResult {
  final QrScanOrganization organization;
  final bool alreadyLinked;
  final String message;

  const QrScanResult({
    required this.organization,
    required this.alreadyLinked,
    required this.message,
  });

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    return QrScanResult(
      organization: QrScanOrganization.fromJson(
          json['organization'] as Map<String, dynamic>),
      alreadyLinked: json['already_linked'] as bool,
      message: json['message'] as String,
    );
  }
}

// ============================================================================
// Datasource — POST /qr/scan
// ============================================================================

final qrDatasourceProvider = Provider<QrDatasource>((ref) {
  return QrDatasource(ref.watch(apiClientProvider));
});

class QrDatasource {
  final Dio _dio;
  QrDatasource(this._dio);

  /// Soumet le code QR scanné et lie le bénéficiaire à l'organisation.
  Future<QrScanResult> scan(String code, {String? deviceInfo}) async {
    try {
      final res = await _dio.post('/qr/scan', data: {
        'code': code,
        if (deviceInfo != null) 'device_info': deviceInfo,
      });
      return QrScanResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
