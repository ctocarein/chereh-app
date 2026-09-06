import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart' show AuthStateAuthenticated;
import '../../data/datasources/evaluation_remote_datasource.dart';
import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/beneficiary_preference.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../presentation/providers/recent_bilans_provider.dart';
import '../widgets/bilan_risk.dart';
import '../widgets/last_bilan_hero.dart';
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

            // ── Security gate banner ──────────────────────────────────
            if (gateRequired && user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(h, 14, h, 0),
                  child: SecurityGateBanner(user: user),
                ),
              ),

            // ── Mon dernier bilan ─────────────────────────────────────
            // Ce que la bénéficiaire vient chercher : où elle en est et ce
            // qu'elle doit faire. La progression d'évaluation n'a plus d'objet
            // ici — elle ne peut plus la faire avancer elle-même.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(h, 18, h, 0),
                child: const LastBilanHero(),
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
              'Ce que votre dernier bilan recommande',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
        ),

        // ── Ce que je dois faire ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(h, 16, h, 0),
            child: const _NextStepCard(),
          ),
        ),

        // ── Thèmes abordés ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(h, 28, h, 0),
            child: Text(
              'Thèmes abordés pendant votre évaluation',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
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
            error: (_, _) => Center(
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
              // Pas de chevron : rien ne s'ouvre. Ces cartes disent ce qui a
              // été abordé, elles ne promettent pas une navigation.
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Ce que je dois faire — la recommandation du dernier bilan
// ============================================================================

class _NextStepCard extends ConsumerWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentBilansProvider);
    final report = async.valueOrNull?.firstOrNull;

    if (report == null) {
      return _NextStepShell(
        color: AppColors.disabled,
        icon: Icons.hourglass_empty_rounded,
        title: 'Pas encore de recommandation',
        body: async.hasError
            ? 'Nous n\'arrivons pas à récupérer votre bilan pour le moment.'
            : 'Après votre évaluation, la conduite à tenir s\'affichera ici.',
      );
    }

    final risk = bilanRiskFrom(report.riskLevel);
    final body = switch (report.recommendation?.trim()) {
      final String r when r.isNotEmpty => r,
      _ => risk.guidance,
    };

    return _NextStepShell(
      color: risk.color,
      icon: risk.icon,
      title: 'Niveau ${risk.label.toLowerCase()}',
      body: body,
      footer: risk.needsCare
          ? TextButton.icon(
              onPressed: () =>
                  context.pushNamed(RouteNames.beneficiaryDepistage),
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('Trouver un centre près de moi'),
              style: TextButton.styleFrom(
                foregroundColor: risk.color,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          : null,
    );
  }
}

class _NextStepShell extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  const _NextStepShell({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.foreground,
                  height: 1.4,
                ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
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
// Bilan récents
// ============================================================================

class _BilanItem {
  final String date;
  final BilanRisk risk;
  final String? title;
  const _BilanItem({required this.date, required this.risk, this.title});
}

_BilanItem _bilanItemFromReport(ReportSummary r) => _BilanItem(
      date: DateFormat('MMM yyyy', 'fr_FR').format(r.createdAt),
      risk: bilanRiskFrom(r.riskLevel),
      title: r.title,
    );

class _BilanCard extends StatelessWidget {
  final _BilanItem item;
  final double width;
  const _BilanCard({required this.item, this.width = 136});

  @override
  Widget build(BuildContext context) {
    final color = item.risk.color;
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
          Icon(item.risk.icon, color: color, size: 22),
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
              item.risk.label,
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
