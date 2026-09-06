/// Ce qu'un évaluateur a réellement accompli.
///
/// Les chiffres viennent des évaluations qu'il a conduites, pas d'un compteur
/// tenu à côté : ils ne peuvent pas s'écarter de la réalité.
class EvaluatorImpact {
  /// Femmes distinctes accompagnées — une visite de suivi ne compte pas double.
  final int womenReached;

  final int evaluationsCompleted;
  final int evaluationsInProgress;

  /// Femmes orientées vers une prise en charge rapide. Le chiffre qui compte
  /// cliniquement.
  final int urgentReferrals;

  /// Communes où il est intervenu.
  final List<String> communes;

  final DateTime? activeSince;

  const EvaluatorImpact({
    this.womenReached = 0,
    this.evaluationsCompleted = 0,
    this.evaluationsInProgress = 0,
    this.urgentReferrals = 0,
    this.communes = const [],
    this.activeSince,
  });

  int get communesCovered => communes.length;

  /// Vrai tant qu'aucune évaluation n'a été conduite : l'écran affiche alors
  /// une invitation plutôt qu'une rangée de zéros.
  bool get isEmpty => womenReached == 0;

  factory EvaluatorImpact.fromJson(Map<String, dynamic> json) => EvaluatorImpact(
        womenReached: _toInt(json['women_reached']),
        evaluationsCompleted: _toInt(json['evaluations_completed']),
        evaluationsInProgress: _toInt(json['evaluations_in_progress']),
        urgentReferrals: _toInt(json['urgent_referrals']),
        communes: (json['communes'] as List<dynamic>? ?? const [])
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
