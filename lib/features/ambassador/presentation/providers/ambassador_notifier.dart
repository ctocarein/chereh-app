import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ambassador_remote_datasource.dart';
import '../../domain/models/ambassador_models.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class AmbassadorState {
  const AmbassadorState();
}

final class AmbassadorLoading extends AmbassadorState {
  const AmbassadorLoading();
}

final class AmbassadorLoaded extends AmbassadorState {
  final AmbassadorMetrics metrics;
  final List<ReferralModel> referrals;
  final GeneratedReferral? lastGenerated;
  final bool isGenerating;

  const AmbassadorLoaded({
    required this.metrics,
    required this.referrals,
    this.lastGenerated,
    this.isGenerating = false,
  });

  AmbassadorLoaded copyWith({
    AmbassadorMetrics? metrics,
    List<ReferralModel>? referrals,
    GeneratedReferral? lastGenerated,
    bool? isGenerating,
  }) =>
      AmbassadorLoaded(
        metrics: metrics ?? this.metrics,
        referrals: referrals ?? this.referrals,
        lastGenerated: lastGenerated ?? this.lastGenerated,
        isGenerating: isGenerating ?? this.isGenerating,
      );
}

final class AmbassadorError extends AmbassadorState {
  final String message;
  const AmbassadorError(this.message);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final ambassadorNotifierProvider =
    NotifierProvider<AmbassadorNotifier, AmbassadorState>(
  AmbassadorNotifier.new,
);

class AmbassadorNotifier extends Notifier<AmbassadorState> {
  @override
  AmbassadorState build() => const AmbassadorLoading();

  /// Charge métriques + referrals en parallèle.
  Future<void> load() async {
    state = const AmbassadorLoading();
    try {
      final ds = ref.read(ambassadorRemoteDatasourceProvider);
      final results = await Future.wait([ds.getMetrics(), ds.getReferrals()]);
      state = AmbassadorLoaded(
        metrics: results[0] as AmbassadorMetrics,
        referrals: results[1] as List<ReferralModel>,
      );
    } catch (e) {
      state = AmbassadorError(e.toString());
    }
  }

  /// Génère ou réutilise un lien de parrainage.
  Future<void> generateLink({String? channel}) async {
    final current = state;
    if (current is! AmbassadorLoaded) return;
    state = current.copyWith(isGenerating: true);
    try {
      final ds = ref.read(ambassadorRemoteDatasourceProvider);
      final generated = await ds.generateReferral(channel: channel);
      // Recharger la liste des referrals
      final referrals = await ds.getReferrals();
      state = current.copyWith(
        lastGenerated: generated,
        referrals: referrals,
        isGenerating: false,
      );
    } catch (e) {
      state = current.copyWith(isGenerating: false);
      rethrow;
    }
  }

  /// Révoque un referral et recharge la liste.
  Future<void> revokeReferral(String referralId) async {
    final current = state;
    if (current is! AmbassadorLoaded) return;
    try {
      final ds = ref.read(ambassadorRemoteDatasourceProvider);
      await ds.revokeReferral(referralId);
      final referrals = await ds.getReferrals();
      state = current.copyWith(referrals: referrals);
    } catch (_) {}
  }
}
