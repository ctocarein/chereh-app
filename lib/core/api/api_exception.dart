import 'package:dio/dio.dart';

/// Exception métier issue d'une erreur HTTP ou réseau.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? data;

  const ApiException(this.message, {this.statusCode, this.errorCode, this.data});

  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final raw = e.response?.data;
    final body = raw is Map<String, dynamic> ? raw : null;
    final msg = body?['message'] as String? ?? e.message ?? 'Erreur réseau';
    return ApiException(
      msg,
      statusCode: code,
      errorCode: body?['error_code'] as String?,
      data: body,
    );
  }

  @override
  String toString() => 'ApiException($statusCode/$errorCode): $message';
}
