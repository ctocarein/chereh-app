import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_token_storage.dart';
import 'api_interceptors.dart';

part 'api_client.g.dart';

/// URL de l'API selon l'environnement.
///
/// Passer via --dart-define=API_BASE_URL=... au lancement :
///   Flutter Web (Laragon local) : https://api.triage.carein:8443/api
///   Émulateur Android           : https://10.0.2.2:8443/api
///   Simulateur iOS              : https://localhost:8443/api
///   Device physique             : https://IP-LOCALE:8443/api
///   Production / défaut         : https://triage.carein.cloud/api
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://triage.carein.cloud/api',
);

@riverpod
Dio apiClient(Ref ref) {
  final storage = ref.watch(authTokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ));

  // En debug natif : accepter les certificats auto-signés (Laragon local).
  // Ignoré sur web (pas d'IOHttpClientAdapter).
  if (kDebugMode && !kIsWeb) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}
