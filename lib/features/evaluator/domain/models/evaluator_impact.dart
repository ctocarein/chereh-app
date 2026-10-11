/// Ce qu'un évaluateur a réellement accompli.
///
/// Les chiffres viennent des évaluations qu'il a conduites, pas d'un compteur
/// tenu à côté : ils ne peuvent pas s'écarter de la réalité.
class EvaluatorImpact {
  /// Femmes distinctes accompagnées — une visite de suivi ne compte pas double.
  final int womenReached;

  /// Femmes distinctes dont au moins une évaluation conduite par lui est allée
  /// à son terme — à la différence de [womenReached], une visite en cours ne
  /// suffit pas.
  final int womenEvaluated;

  /// Femmes dont sa dernière évaluation conclut à un risque modéré ou élevé :
  /// celles qu'il doit revoir ou orienter.
  final int womenToFollow;

  final int evaluationsCompleted;
  final int evaluationsInProgress;

  /// Femmes orientées vers une prise en charge rapide. Le chiffre qui compte
  /// cliniquement.
  final int urgentReferrals;

  /// Communes où il est intervenu.
  final List<String> municipalities;

  final DateTime? activeSince;

  const EvaluatorImpact({
    this.womenReached = 0,
    this.womenEvaluated = 0,
    this.womenToFollow = 0,
    this.evaluationsCompleted = 0,
    this.evaluationsInProgress = 0,
    this.urgentReferrals = 0,
    this.municipalities = const [],
    this.activeSince,
  });

  int get municipalitiesCovered => municipalities.length;

  /// Vrai tant qu'aucune évaluation n'a été conduite : l'écran affiche alors
  /// une invitation plutôt qu'une rangée de zéros.
  bool get isEmpty => womenReached == 0;

  factory EvaluatorImpact.fromJson(Map<String, dynamic> json) => EvaluatorImpact(
        womenReached: _toInt(json['women_reached']),
        womenEvaluated: _toInt(json['women_evaluated']),
        womenToFollow: _toInt(json['women_to_follow']),
        evaluationsCompleted: _toInt(json['evaluations_completed']),
        evaluationsInProgress: _toInt(json['evaluations_in_progress']),
        urgentReferrals: _toInt(json['urgent_referrals']),
        municipalities: (json['municipalities'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        activeSince: switch (json['active_since']) {
          final String s when s.trim().isNotEmpty => DateTime.tryParse(s),
          _ => null,
        },
      );
}

int _toInt(dynamic raw) => (raw as num?)?.toInt() ?? 0;
