/// Niveau de risque de la dernière évaluation.
///
/// Aligné sur `config/risk-level.php` côté API.
enum RiskLevel {
  low,
  moderate,
  high;

  static RiskLevel? fromString(String? value) => switch (value) {
        'low' => RiskLevel.low,
        'moderate' => RiskLevel.moderate,
        'high' => RiskLevel.high,
        _ => null,
      };

  String get label => switch (this) {
        RiskLevel.low => 'Risque faible',
        RiskLevel.moderate => 'Risque modéré',
        RiskLevel.high => 'Risque élevé',
      };
}

/// État d'une session d'évaluation, du point de vue de l'annuaire.
enum EvaluationStatus {
  inProgress,
  completed,
  cancelled,
  expired;

  static EvaluationStatus? fromString(String? value) => switch (value) {
        'in_progress' => EvaluationStatus.inProgress,
        'completed' => EvaluationStatus.completed,
        'cancelled' => EvaluationStatus.cancelled,
        'expired' => EvaluationStatus.expired,
        _ => null,
      };

  String get label => switch (this) {
        EvaluationStatus.inProgress => 'En cours',
        EvaluationStatus.completed => 'Terminée',
        EvaluationStatus.cancelled => 'Interrompue',
        EvaluationStatus.expired => 'Expirée',
      };
}

/// Dernière évaluation d'un bénéficiaire.
class LastEvaluation {
  final String sessionId;
  final EvaluationStatus? status;
  final String? type;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Renseigné uniquement si l'utilisateur courant a lui-même conduit cette
  /// évaluation. L'API le masque aux autres évaluateurs de l'organisation :
  /// l'annuaire dit qu'une évaluation existe, pas ce qu'elle a conclu.
  final RiskLevel? riskLevel;

  const LastEvaluation({
    required this.sessionId,
    this.status,
    this.type,
    this.startedAt,
    this.completedAt,
    this.riskLevel,
  });

  bool get isInProgress => status == EvaluationStatus.inProgress;

  /// Date la plus pertinente à afficher : la fin si l'évaluation est allée
  /// à son terme, le début sinon.
  DateTime? get relevantDate => completedAt ?? startedAt;

  factory LastEvaluation.fromJson(Map<String, dynamic> json) => LastEvaluation(
        sessionId: json['session_id'].toString(),
        status: EvaluationStatus.fromString(json['status'] as String?),
        type: json['type'] as String?,
        startedAt: _parseDate(json['started_at']),
        completedAt: _parseDate(json['completed_at']),
        riskLevel: RiskLevel.fromString(json['risk_level'] as String?),
      );
}

/// Une ligne de l'annuaire des bénéficiaires.
class BeneficiarySummary {
  final String identityId;
  final String? name;
  final String? phone;
  final String? municipality;
  final DateTime? birthDate;
  final LastEvaluation? lastEvaluation;

  const BeneficiarySummary({
    required this.identityId,
    this.name,
    this.phone,
    this.municipality,
    this.birthDate,
    this.lastEvaluation,
  });

  /// Le nom quand il est connu, sinon le numéro : une fiche créée en cours
  /// d'évaluation n'a pas encore de nom, seulement un numéro.
  String get displayLabel => name ?? phone ?? 'Bénéficiaire sans nom';

  /// Vrai tant qu'aucune évaluation n'a été ouverte pour cette personne.
  bool get neverEvaluated => lastEvaluation == null;

  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final hadBirthday = now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) years -= 1;
    return years >= 0 && years < 130 ? years : null;
  }

  /// Initiales pour la pastille de la liste.
  String get initials {
    final source = name;
    if (source == null || source.trim().isEmpty) return '·';
    final parts = source.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '·' : letters;
  }

  factory BeneficiarySummary.fromJson(Map<String, dynamic> json) {
    final evaluation = json['last_evaluation'];
    return BeneficiarySummary(
      identityId: json['identity_id'].toString(),
      name: _emptyToNull(json['name'] as String?),
      phone: _emptyToNull(json['phone'] as String?),
      municipality: _emptyToNull(json['municipality'] as String?),
      birthDate: _parseDate(json['birth_date']),
      lastEvaluation: evaluation is Map<String, dynamic>
          ? LastEvaluation.fromJson(evaluation)
          : null,
    );
  }
}

String? _emptyToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _parseDate(dynamic raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}
