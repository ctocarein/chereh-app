import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import 'auth_state.dart';
import 'auth_token_storage.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    final token = await ref.watch(authTokenStorageProvider).read();
    if (token == null) return const AuthStateUnauthenticated();

    try {
      final user = await ref.read(authRemoteDatasourceProvider).me(token);
      // PIN défini mais gate non ouverte → forcer l'écran PIN
      if (user.gateRequired && user.secretSet) {
        return AuthStatePinRequired(sessionToken: token, hasPin: true);
      }
      return AuthStateAuthenticated(user);
    } catch (_) {
      await ref.read(authTokenStorageProvider).clear();
      return const AuthStateUnauthenticated();
    }
  }

  /// Étape 1 : soumettre le numéro de téléphone.
  Future<void> submitPhone(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRemoteDatasourceProvider).submitPhone(phone);
      if (result is PhoneAuthCreated) {
        return await _saveAndAuthenticate(result.user);
      } else if (result is PhoneAuthPinRequired) {
        return AuthStatePinRequired(
          sessionToken: result.sessionToken,
          hasPin: result.hasPin,
        );
      }
      return const AuthStateUnauthenticated();
    });
  }

  /// Étape 2 : soumettre le code PIN (création ou vérification).
  Future<void> submitPin({
    required String sessionToken,
    required String pin,
    required bool hasPin,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRemoteDatasourceProvider).submitPin(
            sessionToken: sessionToken,
            pin: pin,
            hasPin: hasPin,
          );
      return await _saveAndAuthenticate(user);
    });
  }

  /// Création de PIN depuis l'intérieur de l'app (utilisateur sans PIN).
  Future<void> createPin(String pin) async {
    final current = state.valueOrNull;
    if (current is! AuthStateAuthenticated) return;
    state = await AsyncValue.guard(() async {
      final ds = ref.read(authRemoteDatasourceProvider);
      await ds.submitPin(
        sessionToken: current.user.token,
        pin: pin,
        hasPin: false,
      );
      // Recharger le profil avec gate mis à jour
      final updated = await ds.me(current.user.token);
      return AuthStateAuthenticated(updated);
    });
  }

  Future<AuthState> _saveAndAuthenticate(AuthUser user) async {
    await ref.read(authTokenStorageProvider).write(user.token);
    return AuthStateAuthenticated(user);
  }

  Future<void> logout() async {
    await ref.read(authTokenStorageProvider).clear();
    state = const AsyncValue.data(AuthStateUnauthenticated());
  }
}
