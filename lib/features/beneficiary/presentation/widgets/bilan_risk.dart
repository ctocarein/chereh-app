import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Le niveau de risque d'un bilan, tel que la bénéficiaire doit le lire.
///
/// Le libellé, la couleur et l'icône vivent ici plutôt que dans chaque écran :
/// un « risque élevé » ne peut pas être rouge sur une carte et orange sur une
/// autre.
enum BilanRisk { unknown, low, moderate, high, veryHigh }

BilanRisk bilanRiskFrom(String? raw) => switch (raw) {
      'low' => BilanRisk.low,
      'medium' => BilanRisk.moderate,
      'high' => BilanRisk.high,
      'very_high' => BilanRisk.veryHigh,
      _ => BilanRisk.unknown,
    };

extension BilanRiskPresentation on BilanRisk {
  String get label => switch (this) {
        BilanRisk.low => 'Faible',
        BilanRisk.moderate => 'Modéré',
        BilanRisk.high => 'Élevé',
        BilanRisk.veryHigh => 'Très élevé',
        BilanRisk.unknown => 'Inconnu',
      };

  Color get color => switch (this) {
        BilanRisk.low => AppColors.support,
        BilanRisk.moderate => AppColors.warning,
        BilanRisk.high => AppColors.accent,
        BilanRisk.veryHigh => const Color(0xFFD62828),
        BilanRisk.unknown => AppColors.disabled,
      };

  IconData get icon => switch (this) {
        BilanRisk.low => Icons.check_circle_outline,
        BilanRisk.moderate => Icons.warning_amber_outlined,
        BilanRisk.high => Icons.error_outline,
        BilanRisk.veryHigh => Icons.dangerous_outlined,
        BilanRisk.unknown => Icons.radio_button_unchecked,
      };

  /// Vrai lorsque le bilan appelle une prise en charge sans attendre.
  ///
  /// C'est ce test — et non le niveau lui-même — qui décide de l'apparence
  /// d'alerte et de l'action mise en avant sur l'accueil.
  bool get needsCare => this == BilanRisk.high || this == BilanRisk.veryHigh;

  /// Ce que la bénéficiaire doit retenir, quand le bilan ne porte pas de
  /// recommandation rédigée.
  String get guidance => switch (this) {
        BilanRisk.low =>
          'Rien d\'inquiétant pour le moment. Continuez à vous faire suivre régulièrement.',
        BilanRisk.moderate =>
          'Un examen de contrôle est conseillé. Parlez-en à votre ambassadrice.',
        BilanRisk.high =>
          'Un examen est nécessaire rapidement. Ne restez pas seule avec ça.',
        BilanRisk.veryHigh =>
          'Rendez-vous dans un centre de santé sans attendre.',
        BilanRisk.unknown =>
          'Votre ambassadrice vous expliquera la suite à donner.',
      };
}
