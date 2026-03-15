import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/referral_attribution_datasource.dart';
import '../../data/models/referral_attribution.dart';

/// Orchestrate les 4 méthodes de récupération du token selon la spec §3.2.
///
/// Ordre de priorité :
///   1. Android Install Referrer (~85%)  → token explicite via Play Store referrer
///   2. Presse-papiers (~5%)             → token copié par le JS de la page de redirect
///   3. Fingerprint (~50% en fallback)   → IP + modèle appareil
///
/// (Priorité 2 deep-link est gérée séparément par GoRouter au moment de l'ouverture.)
class ReferralAttributionService {
  static const _prefsKeyDone = 'referral_attribution_done';
  static const _methodChannel =
      MethodChannel('com.chereh.chereh_app/install_referrer');

  // Pattern d'un click_token généré par le backend (Str::random(64) = alphanumérique)
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9]{64}$');

  final ReferralAttributionDatasource _datasource;

  ReferralAttributionService(this._datasource);

  // ─────────────────────────────────────────────────────────────────────────
  // Point d'entrée principal
  // ─────────────────────────────────────────────────────────────────────────

  /// Lance la séquence d'attribution au premier lancement.
  /// Retourne l'attribution trouvée ou null.
  /// Idempotent : ne fait rien si déjà exécuté.
  Future<ReferralAttribution?> run() async {
    final prefs = await SharedPreferences.getInstance();

    // Déjà traité lors d'un lancement précédent
    if (prefs.getBool(_prefsKeyDone) == true) {
      return _loadFromPrefs(prefs);
    }

    final deviceInfo = await _resolveDeviceInfo();

    // Priorité 1 — Android Install Referrer
    final attribution = await _tryInstallReferrer(deviceInfo) ??
        // Priorité 2 — Presse-papiers
        await _tryClipboard(deviceInfo) ??
        // Priorité 3 — Fingerprint
        await _tryFingerprint(deviceInfo);

    // Marque comme traité quoi qu'il arrive pour ne plus relancer à chaque démarrage
    await prefs.setBool(_prefsKeyDone, true);

    if (attribution != null) {
      await _saveToPrefs(prefs, attribution);
    }

    return attribution;
  }

  /// Réinitialise l'état (utile pour les tests ou après logout complet).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyDone);
    await prefs.remove('referral_ambassador_id');
    await prefs.remove('referral_ambassador_name');
    await prefs.remove('referral_code');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Méthode 1 : Android Install Referrer
  // ─────────────────────────────────────────────────────────────────────────

  Future<ReferralAttribution?> _tryInstallReferrer(
      _DeviceInfo deviceInfo) async {
    if (!Platform.isAndroid) return null;
    try {
      final referrer = await _methodChannel
          .invokeMethod<String>('getInstallReferrer')
          .timeout(const Duration(seconds: 5));
      if (referrer == null || referrer.isEmpty) return null;

      // Format attendu : "chereh_token=<64chars>"
      final token = _extractToken(referrer);
      if (token == null) return null;

      return _datasource.claimByToken(
        clickToken:  token,
        deviceModel: deviceInfo.model,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Méthode 2 : Presse-papiers
  // ─────────────────────────────────────────────────────────────────────────

  Future<ReferralAttribution?> _tryClipboard(_DeviceInfo deviceInfo) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return null;

      final token = _tokenPattern.hasMatch(text) ? text : null;
      if (token == null) return null;

      return _datasource.claimByToken(
        clickToken:  token,
        deviceModel: deviceInfo.model,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Méthode 3 : Fingerprint (IP déterminée côté serveur)
  // ─────────────────────────────────────────────────────────────────────────

  Future<ReferralAttribution?> _tryFingerprint(_DeviceInfo deviceInfo) async {
    try {
      return await _datasource.claimByFingerprint(
        deviceModel: deviceInfo.model,
        osVersion:   deviceInfo.osVersion,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String? _extractToken(String referrer) {
    // "chereh_token=<token>" ou juste "<token>"
    final uri = Uri.splitQueryString(referrer);
    final token = uri['chereh_token'] ?? referrer.trim();
    return _tokenPattern.hasMatch(token) ? token : null;
  }

  Future<_DeviceInfo> _resolveDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return _DeviceInfo(
          model:     '${info.manufacturer} ${info.model}',
          osVersion: info.version.release,
        );
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return _DeviceInfo(
          model:     info.utsname.machine,
          osVersion: info.systemVersion,
        );
      }
    } catch (_) {}
    return const _DeviceInfo(model: 'unknown', osVersion: null);
  }

  Future<void> _saveToPrefs(
      SharedPreferences prefs, ReferralAttribution attr) async {
    for (final entry in attr.toPrefsMap().entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  ReferralAttribution? _loadFromPrefs(SharedPreferences prefs) {
    return ReferralAttribution.fromPrefsMap({
      'referral_ambassador_id':   prefs.getString('referral_ambassador_id'),
      'referral_ambassador_name': prefs.getString('referral_ambassador_name'),
      'referral_code':            prefs.getString('referral_code'),
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DTO interne
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceInfo {
  final String model;
  final String? osVersion;
  const _DeviceInfo({required this.model, required this.osVersion});
}
