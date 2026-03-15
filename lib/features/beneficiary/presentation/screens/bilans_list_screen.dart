import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../providers/recent_bilans_provider.dart';

// ============================================================================
// Screen — Liste complète des bilans
// ============================================================================

class BilansListScreen extends ConsumerWidget {
  const BilansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allBilansProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.foreground,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: const BackButton(),
            title: Text(
              'Mes Bilans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
            ),
          ),
          async.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => SliverFillRemaining(
              child: _ErrorState(
                onRetry: () => ref.invalidate(allBilansProvider),
              ),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _BilanTile(report: reports[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tile — un bilan dans la liste
// ============================================================================

class _BilanTile extends StatelessWidget {
  final ReportSummary report;
  const _BilanTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFrom(report.riskLevel);
    final color = _riskColor(level);
    final label = _riskLabel(level);
    final icon = _riskIcon(level);
    final date = DateFormat('d MMM yyyy', 'fr_FR').format(report.createdAt);
    final score = report.score;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icône risque
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge niveau de risque
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            // Score (optionnel)
            if (score != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.round()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  Text(
                    'score',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// États vide / erreur
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              'Aucun bilan disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos bilans apparaîtront ici après avoir complété une évaluation.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les bilans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helpers risque (locaux à ce fichier)
// ============================================================================

enum _RiskLevel { none, low, moderate, high, veryHigh }

_RiskLevel _riskLevelFrom(String raw) => switch (raw) {
      'low' => _RiskLevel.low,
      'medium' => _RiskLevel.moderate,
      'high' => _RiskLevel.high,
      'very_high' => _RiskLevel.veryHigh,
      _ => _RiskLevel.none,
    };

String _riskLabel(_RiskLevel r) => switch (r) {
      _RiskLevel.none => 'Inconnu',
      _RiskLevel.low => 'Faible',
      _RiskLevel.moderate => 'Modéré',
      _RiskLevel.high => 'Élevé',
      _RiskLevel.veryHigh => 'Très élevé',
    };

Color _riskColor(_RiskLevel r) => switch (r) {
      _RiskLevel.none => AppColors.disabled,
      _RiskLevel.low => AppColors.support,
      _RiskLevel.moderate => AppColors.warning,
      _RiskLevel.high => AppColors.accent,
      _RiskLevel.veryHigh => const Color(0xFFD62828),
    };

IconData _riskIcon(_RiskLevel r) => switch (r) {
      _RiskLevel.none => Icons.radio_button_unchecked,
      _RiskLevel.low => Icons.check_circle_outline,
      _RiskLevel.moderate => Icons.warning_amber_outlined,
      _RiskLevel.high => Icons.error_outline,
      _RiskLevel.veryHigh => Icons.dangerous_outlined,
    };
