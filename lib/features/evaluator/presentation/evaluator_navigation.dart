import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../domain/models/beneficiary_summary.dart';
import '../domain/models/evaluation_launch.dart';

/// Ouvre l'évaluation assistée de cette patiente. C'est le serveur qui décide
/// s'il s'agit d'un démarrage, d'une visite de suivi, ou de la reprise d'une
/// session laissée ouverte.
void openBeneficiaryEvaluation(
  BuildContext context,
  BeneficiarySummary beneficiary,
) {
  context.goNamed(
    RouteNames.beneficiaryEvaluation,
    extra: EvaluationLaunch.forSubject(beneficiary.identityId),
  );
}

/// Ouvre une évaluation pour une personne pas encore enregistrée. Sa fiche
/// naît du parcours : le questionnaire demande son numéro, puis sa commune.
void startNewBeneficiaryEvaluation(BuildContext context) {
  context.goNamed(
    RouteNames.beneficiaryEvaluation,
    extra: const EvaluationLaunch.forNewBeneficiary(),
  );
}
