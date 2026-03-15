import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../providers/recent_bilans_provider.dart';

// ============================================================================
// Tab "Mes Rapports" — onglet 2 du home bénéficiaire
// ============================================================================

class ReportsTabScreen extends ConsumerWidget {
  const ReportsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allBilansProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.foreground,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Text(
              'Mes Rapports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
            ),
          ),

          // ── Contenu ───────────────────────────────────────────────────
          async.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.brand, strokeWidth: 2),
              ),
            ),
            error: (_, __) => SliverFillRemaining(
              child: _ErrorState(
                  onRetry: () => ref.invalidate(allBilansProvider)),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ReportCard(report: reports[i]),
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
// Card rapport — liste riche
// ============================================================================

class _ReportCard extends StatelessWidget {
  final ReportSummary report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFrom(report.riskLevel);
    final color = _riskColor(level);
    final label = _riskLabel(level);
    final date = DateFormat('d MMM yyyy', 'fr_FR').format(report.createdAt);
    final title = report.title?.isNotEmpty == true
        ? report.title!
        : 'Bilan de santé';
    final reco = report.recommendation?.isNotEmpty == true
        ? report.recommendation!
        : null;
    final score = report.score;
    final maxScore = report.maxScore ?? 100;

    return GestureDetector(
      onTap: () => context.goNamed(
        RouteNames.beneficiaryReportDetail,
        pathParameters: {'id': report.id.toString()},
        extra: report,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête coloré ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  // Badge niveau de risque
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_riskIcon(level), color: color, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Score / max
                  if (score != null)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${score.round()}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          TextSpan(
                            text: '/${maxScore.round()}',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Corps ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
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
                  if (reco != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFEEF0F2)),
                    const SizedBox(height: 10),
                    Text(
                      reco,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Spécialités chips
                  if (report.specialties.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: report.specialties
                          .take(3)
                          .map((s) => _SpecialtyChip(label: s))
                          .toList(),
                    ),
                  // Lien "Voir le détail"
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Voir le détail',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.brand),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.brand),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brandStrong,
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
            Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              'Aucun rapport disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos rapports détaillés apparaîtront ici après chaque évaluation complétée.',
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
              'Impossible de charger les rapports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
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
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helpers risque
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
      _RiskLevel.low => 'Risque faible',
      _RiskLevel.moderate => 'Risque modéré',
      _RiskLevel.high => 'Risque élevé',
      _RiskLevel.veryHigh => 'Risque très élevé',
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
