import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/referral_attribution_datasource.dart';
import '../../data/models/referral_attribution.dart';
import '../../domain/services/referral_attribution_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider du service
// ─────────────────────────────────────────────────────────────────────────────

final referralAttributionServiceProvider =
    Provider<ReferralAttributionService>((ref) {
  return ReferralAttributionService(
    ref.watch(referralAttributionDatasourceProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// État de l'attribution
// ─────────────────────────────────────────────────────────────────────────────

/// Lance la séquence d'attribution au premier lancement.
/// Le résultat est gardé en mémoire pour la durée de la session.
final referralAttributionProvider =
    FutureProvider<ReferralAttribution?>((ref) async {
  return ref.watch(referralAttributionServiceProvider).run();
});
