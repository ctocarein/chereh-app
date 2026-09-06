import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../providers/recent_bilans_provider.dart';
import 'bilan_risk.dart';

/// La carte d'accueil de la bénéficiaire : son dernier bilan.
///
/// Elle remplace la barre de progression d'évaluation, qui n'avait plus d'objet
/// depuis que l'évaluation est conduite par une ambassadrice ou un agent : la
/// bénéficiaire ne pouvait plus la faire avancer. Ce qu'elle vient chercher
/// dans l'application, c'est où elle en est et ce qu'elle doit faire.
class LastBilanHero extends ConsumerWidget {
  const LastBilanHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentBilansProvider);

    return async.when(
      loading: () => const _HeroShell(
        child: SizedBox(
          height: 128,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const _HeroShell(child: _HeroUnavailable()),
      data: (reports) => reports.isEmpty
          ? const _HeroShell(child: _HeroNoBilan())
          : _HeroBilan(report: reports.first),
    );
  }
}

// ---------------------------------------------------------------------------
// Enveloppe commune
// ---------------------------------------------------------------------------

/// Le dégradé et les cercles décoratifs, partagés par tous les états pour que
/// la carte ne saute pas d'une apparence à l'autre pendant le chargement.
class _HeroShell extends StatelessWidget {
  final Widget child;
  final bool alert;

  const _HeroShell({required this.child, this.alert = false});

  @override
  Widget build(BuildContext context) {
    final colors = alert
        ? const [AppColors.accent, Color(0xFFB8422A)]
        : const [AppColors.brand, Color(0xFF14788A)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -28,
              left: -24,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avec bilan
// ---------------------------------------------------------------------------

class _HeroBilan extends StatelessWidget {
  final ReportSummary report;

  const _HeroBilan({required this.report});

  @override
  Widget build(BuildContext context) {
    final risk = bilanRiskFrom(report.riskLevel);
    final date = DateFormat('d MMMM yyyy', 'fr_FR').format(report.createdAt);

    final message = switch (report.recommendation?.trim()) {
      final String r when r.isNotEmpty => r,
      _ => risk.guidance,
    };

    return _HeroShell(
      alert: risk.needsCare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(risk.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon dernier bilan',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  risk.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // La recommandation est ce que la bénéficiaire doit retenir : elle
          // occupe le corps de la carte, pas une ligne de statut.
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                ),
          ),

          if (report.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final specialty in report.specialties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Un risque élevé met en avant le geste utile — trouver un centre —
          // et relègue la lecture du bilan au second bouton.
          if (risk.needsCare) ...[
            _PrimaryAction(
              icon: Icons.location_on_outlined,
              label: 'Trouver un centre près de moi',
              foreground: AppColors.accent,
              onPressed: () =>
                  context.pushNamed(RouteNames.beneficiaryDepistage),
            ),
            const SizedBox(height: 10),
            _SecondaryAction(
              icon: Icons.description_outlined,
              label: 'Voir mon bilan',
              onPressed: () => context.goNamed(RouteNames.beneficiaryBilans),
            ),
          ] else
            _PrimaryAction(
              icon: Icons.description_outlined,
              label: 'Voir mon bilan',
              foreground: AppColors.brand,
              onPressed: () => context.goNamed(RouteNames.beneficiaryBilans),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sans bilan
// ---------------------------------------------------------------------------

class _HeroNoBilan extends StatelessWidget {
  const _HeroNoBilan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.health_and_safety_outlined,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Pas encore de bilan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Votre bilan apparaîtra ici après votre évaluation avec une '
          'ambassadrice ou un agent de santé. En attendant, vous pouvez '
          'trouver un centre de dépistage près de chez vous.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
        ),
        const SizedBox(height: 18),
        _PrimaryAction(
          icon: Icons.location_on_outlined,
          label: 'Trouver un centre près de moi',
          foreground: AppColors.brand,
          onPressed: () => context.pushNamed(RouteNames.beneficiaryDepistage),
        ),
      ],
    );
  }
}

class _HeroUnavailable extends StatelessWidget {
  const _HeroUnavailable();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Bilan indisponible',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Nous n\'arrivons pas à récupérer votre bilan. Vérifiez votre '
          'connexion, il reste enregistré.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Boutons
// ---------------------------------------------------------------------------

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback onPressed;

  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
