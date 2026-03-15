import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_token_storage.g.dart';

const _kTokenKey = 'chereh_auth_token';

@riverpod
AuthTokenStorage authTokenStorage(Ref ref) => AuthTokenStorage();

class AuthTokenStorage {
  final _storage = const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _kTokenKey);

  Future<void> write(String token) => _storage.write(key: _kTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _kTokenKey);
}
