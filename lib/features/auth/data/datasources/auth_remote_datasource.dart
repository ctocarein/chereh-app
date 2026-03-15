import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/auth_state.dart';

part 'auth_remote_datasource.g.dart';

// ---------------------------------------------------------------------------
// Résultat discriminé de POST /identity/phone
// ---------------------------------------------------------------------------

sealed class PhoneAuthResult {}

/// Authentification immédiate (nouveau compte OU gate non requis).
class PhoneAuthCreated extends PhoneAuthResult {
  final AuthUser user;
  PhoneAuthCreated(this.user);
}

/// Gate de sécurité requise — afficher l'écran PIN.
/// [hasPin] false → créer un PIN   /   true → saisir le PIN existant
class PhoneAuthPinRequired extends PhoneAuthResult {
  final String sessionToken;
  final bool hasPin;
  PhoneAuthPinRequired({required this.sessionToken, required this.hasPin});
}

// ---------------------------------------------------------------------------

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) {
  return AuthRemoteDatasource(ref.watch(apiClientProvider));
}

class AuthRemoteDatasource {
  final Dio _dio;
  AuthRemoteDatasource(this._dio);

  // -------------------------------------------------------------------------
  // POST /identity/phone  { phone }   — loginOrCreate
  //
  // Réponse :
  //   { token, identity, security_gate: { gate_required, secret_set, ... }, is_new? }
  // -------------------------------------------------------------------------
  Future<PhoneAuthResult> submitPhone(String phone) async {
    try {
      final res = await _dio.post('/identity/phone', data: {'phone': phone});
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final gate = (data['security_gate'] as Map<String, dynamic>?) ?? {};
      final gateRequired = (gate['gate_required'] as bool?) ?? false;
      final secretSet = (gate['secret_set'] as bool?) ?? false;

      // PIN existant → écran PIN obligatoire
      if (gateRequired && secretSet) {
        return PhoneAuthPinRequired(sessionToken: token, hasPin: true);
      }

      // Pas de PIN ou gate ouvert → authentification directe (données masquées si gateRequired)
      return PhoneAuthCreated(
        _parseIdentity(data, token, phone: phone, gateRequired: gateRequired, secretSet: secretSet),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // -------------------------------------------------------------------------
  // Étape PIN :
  //   hasPin = false → PATCH /identity/secret  { secret: pin }
  //   hasPin = true  → POST  /identity/unlock   { method: 'pin', secret: pin }
  // Puis GET /identity/me pour retourner l'utilisateur complet.
  // -------------------------------------------------------------------------
  Future<AuthUser> submitPin({
    required String sessionToken,
    required String pin,
    required bool hasPin,
  }) async {
    try {
      final headers = {'Authorization': 'Bearer $sessionToken'};

      if (hasPin) {
        await _dio.post(
          '/identity/unlock',
          data: {'method': 'pin', 'secret': pin},
          options: Options(headers: headers),
        );
      } else {
        await _dio.patch(
          '/identity/secret',
          data: {'secret': pin},
          options: Options(headers: headers),
        );
      }

      return await me(sessionToken);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // -------------------------------------------------------------------------
  // GET /identity/me
  // Réponse : { identity: { id, status, memberships: [...], credentials: [...] } }
  // -------------------------------------------------------------------------
  Future<AuthUser> me(String token) async {
    try {
      final res = await _dio.get(
        '/identity/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      final gate = (data['security_gate'] as Map<String, dynamic>?) ?? {};
      final gateRequired = (gate['gate_required'] as bool?) ?? false;
      final secretSet = (gate['secret_set'] as bool?) ?? false;
      return _parseIdentity(data, token, gateRequired: gateRequired, secretSet: secretSet);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/identity/logout');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // -------------------------------------------------------------------------
  // Parser unifié
  // -------------------------------------------------------------------------

  /// [data]  : réponse brute contenant une clé `identity`
  /// [token] : token Sanctum à stocker
  /// [phone] : fourni par l'appelant quand les credentials ne sont pas chargés
  ///           (réponse de /identity/phone) ; sinon extrait des credentials.
  AuthUser _parseIdentity(
    Map<String, dynamic> data,
    String token, {
    String? phone,
    bool gateRequired = false,
    bool secretSet = false,
  }) {
    final identity = (data['identity'] as Map<String, dynamic>?) ?? {};
    final memberships = (identity['memberships'] as List?) ?? [];
    final credentials = (identity['credentials'] as List?) ?? [];

    final profile = (identity['personal_profile'] as Map<String, dynamic>?) ?? {};
    final firstName = profile['first_name'] as String? ?? '';
    final lastName  = profile['last_name']  as String? ?? '';
    final name = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    final resolvedPhone = phone ??
        credentials
            .cast<Map<String, dynamic>>()
            .firstWhere((c) => c['type'] == 'phone', orElse: () => {})['identifier']
            ?.toString() ??
        '';

    final role = _detectRole(memberships);

    return AuthUser(
      id: identity['id']?.toString() ?? '',
      name: name,
      phone: resolvedPhone,
      role: role,
      token: token,
      gateRequired: gateRequired,
      secretSet: secretSet,
    );
  }

  /// Détermine le rôle dominant en scannant tous les memberships.
  /// Priorité : FieldAgent > Ambassador > Beneficiary.
  UserRole _detectRole(List memberships) {
    final roles = memberships
        .cast<Map<String, dynamic>>()
        .map((m) => m['role']?.toString() ?? '')
        .toSet();
    if (roles.contains('FieldAgent')) return UserRole.fieldAgent;
    if (roles.contains('Ambassador')) return UserRole.ambassador;
    return UserRole.beneficiary;
  }
}
