import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';

/// Écran d'introduction affiché à la première connexion du bénéficiaire.
/// Présente CheReh et invite à démarrer l'évaluation.
class BeneficiaryIntroScreen extends StatelessWidget {
  const BeneficiaryIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rp = context.rp;

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rp.maxContentW),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: rp.hPad),
              child: Column(
                children: [
                  const Spacer(),

                  // Logo
                  Container(
                    width: rp.logoSz,
                    height: rp.logoSz,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(rp.radiusL),
                    ),
                    padding: EdgeInsets.all(rp.logoSz * 0.17),
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Icon(
                        Icons.health_and_safety_outlined,
                        size: rp.logoSz * 0.52,
                        color: AppColors.brand,
                      ),
                    ),
                  ),

                  SizedBox(height: rp.spL),

                  Text(
                    'Parlons de vous',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: rp.spM),

                  Text(
                    'CheReh va vous poser quelques questions pour mieux comprendre '
                    'votre situation et vous orienter vers les ressources adaptées.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: rp.spM),

                  _InfoRow(icon: Icons.timer_outlined,    text: 'Environ 5 à 10 minutes'),
                  SizedBox(height: rp.spS),
                  _InfoRow(icon: Icons.lock_outline,      text: 'Vos réponses sont confidentielles'),
                  SizedBox(height: rp.spS),
                  _InfoRow(icon: Icons.wifi_off_outlined, text: 'Fonctionne hors connexion'),

                  const Spacer(),

                  AppButton(
                    label: 'Commencer l\'évaluation',
                    onPressed: () =>
                        context.goNamed(RouteNames.beneficiaryEvaluation),
                  ),

                  SizedBox(height: rp.spM),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
        ),
      ],
    );
  }
}
