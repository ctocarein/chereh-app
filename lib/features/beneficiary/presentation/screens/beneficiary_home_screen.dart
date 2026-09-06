import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart' show AuthStateAuthenticated;
import '../../data/datasources/evaluation_remote_datasource.dart';
import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/beneficiary_preference.dart';
import '../../data/datasources/evaluation_local_datasource.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../presentation/providers/evaluation_notifier.dart';
import '../../presentation/providers/evaluation_state.dart';
import '../../presentation/providers/recent_bilans_provider.dart';
import '../../../referral/presentation/widgets/referral_welcome_banner.dart';
import 'reports_tab_screen.dart';

final completedThemeKeysProvider = FutureProvider<Set<String>>((ref) async {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState is! AuthStateAuthenticated) return {};
  return BeneficiaryPreference.getCompletedThemes(authState.user.id);
});

// ============================================================================
// Root scaffold with bottom navigation
// ============================================================================

class BeneficiaryHomeScreen extends ConsumerStatefulWidget {
  const BeneficiaryHomeScreen({super.key});

  @override
  ConsumerState<BeneficiaryHomeScreen> createState() =>
      _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState
    extends ConsumerState<BeneficiaryHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tab,
        children: const [
          _HomeTab(),
          _MonSuiviTab(),
          ReportsTabScreen(),
          SharedProfileTab(),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        items: [
          HomeNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Accueil',
            active: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          HomeNavItem(
            icon: Icons.favorite_border_rounded,
            activeIcon: Icons.favorite_rounded,
            label: 'Mon suivi',
            active: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
          HomeNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Rapports',
            active: _tab == 2,
            onTap: () => setState(() => _tab = 2),
          ),
          HomeNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
            active: _tab == 3,
            onTap: () => setState(() => _tab = 3),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab 0 — Accueil
// ============================================================================

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.valueOrNull is AuthStateAuthenticated
        ? (authAsync.valueOrNull as AuthStateAuthenticated).user
        : null;

    final name = user?.name ?? '';
    final firstName = name.split(' ').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final gateRequired = user?.gateRequired ?? false;
    final rp = context.rp;
    final h = rp.hPad;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(h, 16, h, 0),
                  child: Row(
                    children: [
                      HomeAvatar(initial: initial),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $firstName\u00a0!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foreground,
                                  ),
                            ),
                            Text(
                              'Prenez soin de vous aujourd\'hui',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      HomeIconButton(
                        icon: Icons.qr_code_scanner_outlined,
                        onTap: () =>
                            context.pushNamed(RouteNames.beneficiaryQr),
                        tooltip: 'Scanner un QR',
                      ),
                      const SizedBox(width: 8),
                      const HomeNotificationButton(badge: 0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bannière de bienvenue parrainage ─────────────────────────
            const SliverToBoxAdapter(child: ReferralWelcomeBanner()),

            // ── Security gate banner ──────────────────────────────────
            if (gateRequired && user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(h, 14, h, 0),
                  child: SecurityGateBanner(user: user),
                ),
              ),

            // ── Hero évaluation card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(h, 18, h, 0),
                child: _HeroEvaluationCard(gateRequired: gateRequired),
              ),
            ),

            // ── Bilan récents ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(h, 26, h, 0),
                child: HomeSectionHeader(
                  title: 'Bilan Récents',
                  actionLabel: 'Voir tout',
                  onAction: () => context.pushNamed(RouteNames.beneficiaryBilans),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RecentBilansRow(),
            ),

            // ── Services ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(h, 24, h, 0),
                child: const HomeSectionHeader(title: 'Services'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(h, 12, h, 0),
                child: Column(
                  children: [
                    HomeActionTile(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.accent,
                      iconBg: AppColors.accentSoft,
                      title: 'Dépistage de Proximité',
                      subtitle: 'Trouver un site près de vous',
                      onTap: () => context
                          .pushNamed(RouteNames.beneficiaryDepistage),
                    ),
                    const SizedBox(height: 10),
                    HomeActionTile(
                      icon: Icons.support_agent_outlined,
                      iconColor: AppColors.support,
                      iconBg: const Color(0xFFD4F5E5),
                      title: 'Parler À Un Conseiller',
                      subtitle: 'Consultation ou rendez-vous médical',
                      badge: 'Premium',
                      onTap: () => context
                          .pushNamed(RouteNames.beneficiaryConseiller),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ============================================================================
// Tab 1 — Mon suivi
// ============================================================================

// Groupes affichés dans "Mon suivi", dans l'ordre souhaité
const _suiviGroups = [
  (
    intentions: [ThematicIntention.assessment, ThematicIntention.screening],
    label: 'Évaluation',
    subtitle: 'Comprendre vos symptômes et risques',
  ),
  (
    intentions: [ThematicIntention.education],
    label: 'Comprendre',
    subtitle: 'Explications sur vos résultats et risques',
  ),
  (
    intentions: [
      ThematicIntention.monitoring,
      ThematicIntention.followUp,
      ThematicIntention.preparation,
    ],
    label: 'Mon suivi',
    subtitle: 'Préparer et suivre votre parcours de santé',
  ),
  (
    intentions: [ThematicIntention.sharedDecision],
    label: 'Décision partagée',
    subtitle: 'Participer à vos choix de soins',
  ),
];

class _MonSuiviTab extends ConsumerWidget {
  const _MonSuiviTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocsAsync = ref.watch(thematicBlocsProvider);
    final rp = context.rp;
    final h = rp.hPad;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(h, 24, h, 0),
              child: Text(
                'Mon suivi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(h, 4, h, 0),
            child: Text(
              'Choisissez un sujet pour démarrer une discussion',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: blocsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 48),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'Impossible de charger les sujets',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ),
            data: (blocs) => _SuiviGroupedList(blocs: blocs, hPad: h),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _SuiviGroupedList extends StatelessWidget {
  final List<ThematicBlocDto> blocs;
  final double hPad;
  const _SuiviGroupedList({required this.blocs, required this.hPad});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (final group in _suiviGroups) {
      final grouped = blocs
          .where((b) => group.intentions.contains(b.intention))
          .toList();
      if (grouped.isEmpty) continue;

      sections.add(
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                group.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              ...grouped.map(
                (bloc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuiviCard(bloc: bloc),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 0),
        child: Center(
          child: Text(
            'Aucun sujet disponible pour le moment',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

class _SuiviCard extends ConsumerWidget {
  final ThematicBlocDto bloc;
  const _SuiviCard({required this.bloc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed =
        ref.watch(completedThemeKeysProvider).valueOrNull ?? {};
    final isDone = completed.contains(bloc.key);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Les sujets ne sont plus cliquables : l'évaluation est conduite par
        // une ambassadrice ou un agent, pas depuis cet écran.
        onTap: null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? AppColors.support.withValues(alpha: 0.4)
                  : AppColors.surfaceAlt,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.support.withValues(alpha: 0.12)
                          : AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      bloc.iconData,
                      color: isDone ? AppColors.support : AppColors.brand,
                      size: 24,
                    ),
                  ),
                  if (isDone)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.support,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bloc.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.support.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Fait',
                              style: TextStyle(
                                color: AppColors.support,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (bloc.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        bloc.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// Bilan récents — widget dynamique
// ============================================================================

class _RecentBilansRow extends ConsumerWidget {
  const _RecentBilansRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentBilansProvider);

    return async.when(
      loading: () => const SizedBox(
        height: 124,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Text(
          'Impossible de charger les bilans',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Text(
              'Aucun bilan disponible pour l\'instant',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          );
        }
        final items = reports.map(_bilanItemFromReport).toList();
        final rp = context.rp;
        final cardW = rp.isTablet ? 160.0 : 136.0;
        return SizedBox(
          height: rp.isTablet ? 144 : 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(rp.hPad, 10, rp.hPad, 4),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _BilanCard(item: items[i], width: cardW),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Résumé de l'évaluation — provider léger pour la home card
// ============================================================================

class _EvalSummary {
  final double progress;
  final bool hasStarted;
  final bool isComplete;
  final String? terminationType;
  final String? blocLabel;
  final int completedCount;
  const _EvalSummary({
    required this.progress,
    required this.hasStarted,
    required this.isComplete,
    this.terminationType,
    this.blocLabel,
    this.completedCount = 0,
  });
}

/// Lit l'état live du notifier si disponible, sinon charge le stockage local.
final _evalSummaryProvider = FutureProvider<_EvalSummary>((ref) async {
  final completed = await ref.watch(completedThemeKeysProvider.future);
  final count = completed.length;

  final live = ref.watch(evaluationNotifierProvider);
  if (live is EvaluationActive) {
    return _EvalSummary(
      progress: live.progress,
      hasStarted: true,
      isComplete: false,
      blocLabel: live.blocLabel,
      completedCount: count,
    );
  }
  if (live is EvaluationComplete) {
    return _EvalSummary(
      progress: 1.0,
      hasStarted: true,
      isComplete: true,
      terminationType: live.session.terminationType,
      blocLabel: live.blocLabel,
      completedCount: count,
    );
  }
  final stored = await ref.read(evaluationLocalDatasourceProvider).load();
  if (stored == null) {
    return _EvalSummary(
        progress: 0.0, hasStarted: false, isComplete: false, completedCount: count);
  }
  if (stored.isComplete) {
    return _EvalSummary(
      progress: 1.0,
      hasStarted: true,
      isComplete: true,
      terminationType: stored.terminationType,
      blocLabel: stored.blocLabel,
      completedCount: count,
    );
  }
  final answered = stored.answers.length;
  final total = stored.questionHistory.isNotEmpty
      ? stored.questionHistory.last.totalSteps
      : null;
  final progress = total != null && total > 0
      ? (answered / total).clamp(0.0, 1.0)
      : (answered > 0 ? 0.05 : 0.0);
  return _EvalSummary(
    progress: progress,
    hasStarted: stored.sessionId != null,
    isComplete: false,
    blocLabel: stored.blocLabel,
    completedCount: count,
  );
});

// ============================================================================
// Hero evaluation card
// ============================================================================

class _HeroEvaluationCard extends ConsumerStatefulWidget {
  final bool gateRequired;
  const _HeroEvaluationCard({this.gateRequired = false});

  @override
  ConsumerState<_HeroEvaluationCard> createState() =>
      _HeroEvaluationCardState();
}

class _HeroEvaluationCardState extends ConsumerState<_HeroEvaluationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_evalSummaryProvider);
    final summary = summaryAsync.valueOrNull ??
        const _EvalSummary(progress: 0.0, hasStarted: false, isComplete: false);

    final isUrgent = summary.terminationType == 'urgent_referral';
    final pct = (summary.progress * 100).round();
    final statusLabel = summary.isComplete
        ? 'Évaluation terminée ✓'
        : summary.hasStarted
            ? 'En cours — $pct\u00a0%'
            : 'Pas encore commencé';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, Color(0xFF14788A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.4),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            summary.isComplete
                                ? (summary.terminationType == 'urgent_referral'
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded)
                                : Icons.health_and_safety_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.blocLabel ??
                                  (summary.isComplete
                                      ? 'Évaluation terminée'
                                      : summary.hasStarted
                                          ? 'Évaluation en cours'
                                          : 'Mon Évaluation'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.isComplete
                                  ? (summary.completedCount > 1
                                      ? '${summary.completedCount} thèmes explorés · Continuez dans Mon suivi'
                                      : 'Explorez d\'autres sujets dans Mon suivi')
                                  : summary.hasStarted
                                      ? 'Reprenez là où vous en étiez'
                                      : 'Comprendre mes symptômes et risques',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white
                                        .withValues(alpha: 0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pct\u00a0%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: summary.progress,
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusLabel,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.gateRequired)
                    const _LockedCta()
                  else if (summary.terminationType == 'urgent_referral')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context
                                .pushNamed(RouteNames.beneficiaryDepistage),
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                            ),
                            label: const Text('Trouver un site de depistage'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .pushNamed(RouteNames.beneficiaryConseiller),
                            icon: const Icon(
                              Icons.support_agent_outlined,
                              size: 20,
                            ),
                            label: const Text('Parler a un conseiller'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.goNamed(RouteNames.beneficiaryBilans),
                        icon: const Icon(
                          Icons.description_outlined,
                          size: 20,
                        ),
                        label: const Text('Voir mes bilans'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brand,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
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
class _LockedCta extends ConsumerWidget {
  const _LockedCta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final token = user is AuthStateAuthenticated ? user.user.token : null;

    return GestureDetector(
      onTap: token == null
          ? null
          : () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => _PinSetupWrapper(sessionToken: token),
                ),
              ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Créez un PIN pour accéder',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 13),
          ],
        ),
      ),
    );
  }
}

/// Wrapper qui pop automatiquement quand la gate est levée après création du PIN.
class _PinSetupWrapper extends ConsumerWidget {
  final String sessionToken;
  const _PinSetupWrapper({required this.sessionToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authNotifierProvider, (prev, next) {
      final prevState = prev?.valueOrNull;
      final nextState = next.valueOrNull;
      if (prevState is AuthStateAuthenticated &&
          prevState.user.gateRequired &&
          nextState is AuthStateAuthenticated &&
          !nextState.user.gateRequired) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    });
    return PinScreen(sessionToken: sessionToken, hasPin: false);
  }
}

// ============================================================================
// Bilan récents
// ============================================================================

enum _RiskLevel { none, low, moderate, high, veryHigh }

class _BilanItem {
  final String date;
  final _RiskLevel risk;
  final String label;
  final String? title;
  const _BilanItem(
      {required this.date, required this.risk, required this.label, this.title});
}

_BilanItem _bilanItemFromReport(ReportSummary r) {
  final level = switch (r.riskLevel) {
    'low' => _RiskLevel.low,
    'medium' => _RiskLevel.moderate,
    'high' => _RiskLevel.high,
    'very_high' => _RiskLevel.veryHigh,
    _ => _RiskLevel.none,
  };
  final label = switch (level) {
    _RiskLevel.low => 'Faible',
    _RiskLevel.moderate => 'Modéré',
    _RiskLevel.high => 'Élevé',
    _RiskLevel.veryHigh => 'Très élevé',
    _RiskLevel.none => 'Inconnu',
  };
  final date = DateFormat('MMM yyyy', 'fr_FR').format(r.createdAt);
  return _BilanItem(date: date, risk: level, label: label, title: r.title);
}

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

class _BilanCard extends StatelessWidget {
  final _BilanItem item;
  final double width;
  const _BilanCard({required this.item, this.width = 136});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(item.risk);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_riskIcon(item.risk), color: color, size: 22),
          const Spacer(),
          if (item.title != null) ...[
            Text(
              item.title!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
          ],
          Text(
            item.date,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
