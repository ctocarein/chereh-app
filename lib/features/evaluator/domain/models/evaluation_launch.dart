/// Comment une évaluation est ouverte depuis un espace d'évaluateur.
///
/// Passé en `extra` de la route d'évaluation. Deux cas seulement :
/// une bénéficiaire déjà connue, désignée par son identifiant, ou une nouvelle
/// personne — auquel cas la fiche est créée par le démarrage lui-même, et son
/// numéro puis sa commune sont collectés par le questionnaire.
class EvaluationLaunch {
  /// Identifiant de la bénéficiaire, quand elle est déjà enregistrée.
  final String? subjectId;

  /// Demande au serveur de créer la fiche en même temps que la session.
  final bool newSubject;

  const EvaluationLaunch({this.subjectId, this.newSubject = false});

  /// Reprend ou ouvre une évaluation pour une bénéficiaire connue.
  const EvaluationLaunch.forSubject(String id)
      : subjectId = id,
        newSubject = false;

  /// Ouvre une évaluation pour quelqu'un qui n'est pas encore enregistré.
  const EvaluationLaunch.forNewBeneficiary()
      : subjectId = null,
        newSubject = true;

  /// L'évaluateur conduit l'évaluation pour un tiers, et non pour lui-même.
  bool get isAssisted => subjectId != null || newSubject;

  /// Tolère l'ancienne forme, où `extra` était directement l'identifiant.
  factory EvaluationLaunch.fromExtra(Object? extra) => switch (extra) {
        EvaluationLaunch launch => launch,
        String id => EvaluationLaunch.forSubject(id),
        _ => const EvaluationLaunch(),
      };
}
