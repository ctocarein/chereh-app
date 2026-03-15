import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/report_remote_datasource.dart';

// ============================================================================
// Screen détail d'un rapport — /beneficiary/reports/:id
//
// Reçoit le ReportSummary via GoRouter extra (pas de re-fetch réseau).
// En cas d'extra manquant, charge par ID via reportByIdProvider.
// ============================================================================

class ReportDetailScreen extends ConsumerWidget {
  final int reportId;
  final ReportSummary? initialData; // passé en extra depuis la liste

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si on a déjà les données (navigation depuis la liste), on les utilise.
    // Sinon on fetch par ID (accès direct à l'URL ou lien externe).
    final report = initialData != null
        ? AsyncValue.data(initialData!)
        : ref.watch(reportByIdProvider(reportId));

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: report.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.brand, strokeWidth: 2),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.disabled),
              const SizedBox(height: 12),
              Text(
                'Rapport introuvable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(reportByIdProvider(reportId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (r) => _ReportDetailBody(report: r),
      ),
    );
  }
}

// ============================================================================
// Corps principal
// ============================================================================

class _ReportDetailBody extends StatelessWidget {
  final ReportSummary report;
  const _ReportDetailBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFrom(report.riskLevel);
    final color = _riskColor(level);
    final label = _riskLabel(level);
    final score = report.score;
    final maxScore = report.maxScore ?? 100;
    final title = report.title?.isNotEmpty == true
        ? report.title!
        : 'Bilan de santé';
    final date =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(report.createdAt);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── SliverAppBar ────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          expandedHeight: 220,
          leading: const BackButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroHeader(
              title: title,
              date: date,
              label: label,
              color: color,
              score: score,
              maxScore: maxScore,
              reportCode: report.reportCode,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),

        // ── Contenu ─────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Résumé / findings
              if (report.summary.isNotEmpty) ...[
                _SectionTitle(
                    icon: Icons.summarize_outlined, label: 'Résumé'),
                const SizedBox(height: 10),
                _SummaryCard(items: report.summary),
                const SizedBox(height: 20),
              ],

              // Recommandation
              if (report.recommendation?.isNotEmpty == true) ...[
                _SectionTitle(
                    icon: Icons.tips_and_updates_outlined,
                    label: 'Recommandation'),
                const SizedBox(height: 10),
                _RecommendationCard(text: report.recommendation!),
                const SizedBox(height: 20),
              ],

              // Spécialités
              if (report.specialties.isNotEmpty) ...[
                _SectionTitle(
                    icon: Icons.medical_services_outlined,
                    label: 'Spécialités recommandées'),
                const SizedBox(height: 10),
                _SpecialtiesCard(specialties: report.specialties),
                const SizedBox(height: 20),
              ],

              // Informations du rapport
              _SectionTitle(
                  icon: Icons.info_outline, label: 'Informations'),
              const SizedBox(height: 10),
              _InfoCard(report: report, color: color, label: label),
            ]),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Hero header (zone expandable de la SliverAppBar)
// ============================================================================

class _HeroHeader extends StatelessWidget {
  final String title;
  final String date;
  final String label;
  final Color color;
  final double? score;
  final double maxScore;
  final String? reportCode;

  const _HeroHeader({
    required this.title,
    required this.date,
    required this.label,
    required this.color,
    this.score,
    required this.maxScore,
    this.reportCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Infos texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Cercle de score
              if (score != null) ...[
                const SizedBox(width: 16),
                _ScoreCircle(score: score!, maxScore: maxScore),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cercle de score ──────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final double score;
  final double maxScore;
  const _ScoreCircle({required this.score, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final pct = (score / maxScore).clamp(0.0, 1.0);
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  height: 1,
                ),
              ),
              Text(
                '/ ${maxScore.round()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Sections de contenu
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
        ),
      ],
    );
  }
}

// ── Résumé ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<dynamic> items;
  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final text = item is Map ? item['text']?.toString() : item.toString();
          if (text == null || text.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.foreground),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Recommandation ───────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final String text;
  const _RecommendationCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.brandStrong,
              height: 1.5,
            ),
      ),
    );
  }
}

// ── Spécialités ──────────────────────────────────────────────────────────────

class _SpecialtiesCard extends StatelessWidget {
  final List<String> specialties;
  const _SpecialtiesCard({required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: specialties
            .map((s) => _SpecialtyChip(label: s))
            .toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_hospital_outlined,
              size: 13, color: AppColors.brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brandStrong,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Informations ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ReportSummary report;
  final Color color;
  final String label;
  const _InfoCard(
      {required this.report, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Niveau de risque',
            value: label,
            valueColor: color,
          ),
          if (report.reportCode != null) ...[
            const Divider(height: 20, color: Color(0xFFEEF0F2)),
            _InfoRow(
              label: 'Code rapport',
              value: report.reportCode!,
            ),
          ],
          if (report.score != null) ...[
            const Divider(height: 20, color: Color(0xFFEEF0F2)),
            _InfoRow(
              label: 'Score',
              value:
                  '${report.score!.round()} / ${(report.maxScore ?? 100).round()}',
            ),
          ],
          const Divider(height: 20, color: Color(0xFFEEF0F2)),
          _InfoRow(
            label: 'Date',
            value: DateFormat('d MMMM yyyy', 'fr_FR').format(report.createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.foreground,
              ),
        ),
      ],
    );
  }
}

// ============================================================================
// Provider par ID (fallback si pas d'extra)
// ============================================================================

final reportByIdProvider =
    FutureProvider.family<ReportSummary, int>((ref, id) async {
  return ref.watch(reportRemoteDatasourceProvider).getReportById(id);
});

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
