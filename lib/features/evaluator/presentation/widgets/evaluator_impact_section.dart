import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/evaluator_impact_datasource.dart';
import '../../domain/models/evaluator_impact.dart';

/// Ce que l'évaluateur a accompli : femmes accompagnées, zones couvertes,
/// orientations urgentes.
///
/// Remplace, pour l'ambassadrice et l'agent, les services destinés aux
/// bénéficiaires — trouver un dépistage, parler à un conseiller — qui n'ont
/// rien à faire dans l'espace de quelqu'un qui accompagne les autres.
class EvaluatorImpactSection extends ConsumerWidget {
  const EvaluatorImpactSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(evaluatorImpactProvider);

    return impact.when(
      loading: () => const _ImpactSkeleton(),
      error: (_, _) => const _ImpactUnavailable(),
      data: (data) => data.isEmpty ? const _ImpactEmpty() : _ImpactBody(impact: data),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenu
// ---------------------------------------------------------------------------

class _ImpactBody extends StatelessWidget {
  final EvaluatorImpact impact;

  const _ImpactBody({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${impact.womenReached}',
                label: impact.womenReached > 1
                    ? 'femmes accompagnées'
                    : 'femme accompagnée',
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                background: AppColors.accentSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: '${impact.municipalitiesCovered}',
                label: impact.municipalitiesCovered > 1
                    ? 'zones couvertes'
                    : 'zone couverte',
                icon: Icons.place_rounded,
                color: AppColors.brandStrong,
                background: AppColors.brandSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${impact.evaluationsCompleted}',
                label: 'évaluations terminées',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF2E7D53),
                background: const Color(0xFFDDF3E7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: '${impact.evaluationsInProgress}',
                label: 'en cours',
                icon: Icons.pending_outlined,
                color: const Color(0xFF8A6410),
                background: const Color(0xFFFBF0D8),
              ),
            ),
          ],
        ),

        // N'apparaît que s'il y en a : une ligne à zéro ne dirait rien, alors
        // qu'une seule orientation urgente mérite d'être vue.
        if (impact.urgentReferrals > 0) ...[
          const SizedBox(height: 10),
          _UrgentBanner(count: impact.urgentReferrals),
        ],

        if (impact.municipalities.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Zones couvertes',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in impact.municipalities) _MunicipalityChip(name: name),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  final int count;

  const _UrgentBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9E3DD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFC4B8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high_rounded,
              size: 18, color: Color(0xFF9E3A22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count > 1
                  ? '$count femmes orientées vers une prise en charge rapide'
                  : '1 femme orientée vers une prise en charge rapide',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A2E1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MunicipalityChip extends StatelessWidget {
  final String name;

  const _MunicipalityChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// États sans données
// ---------------------------------------------------------------------------

class _ImpactEmpty extends StatelessWidget {
  const _ImpactEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism_outlined,
              size: 34, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            'Votre impact apparaîtra ici',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dès votre première évaluation, vous verrez les femmes accompagnées '
            'et les zones que vous couvrez.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ImpactSkeleton extends StatelessWidget {
  const _ImpactSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _ImpactUnavailable extends StatelessWidget {
  const _ImpactUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Impact indisponible hors connexion.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
