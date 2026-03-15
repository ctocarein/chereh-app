import 'package:dio/dio.dart';

import '../auth/auth_token_storage.dart';

/// Injecte le Bearer token Sanctum sur chaque requête.
/// Si 401, efface le token (déconnexion forcée gérée par le router).
class AuthInterceptor extends Interceptor {
  final AuthTokenStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storage.clear();
    }
    handler.next(err);
  }
}
