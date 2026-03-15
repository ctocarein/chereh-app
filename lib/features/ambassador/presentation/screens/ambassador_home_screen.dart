import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../beneficiary/data/datasources/evaluation_local_datasource.dart';
import '../../../beneficiary/presentation/providers/evaluation_notifier.dart';
import '../../../beneficiary/presentation/providers/evaluation_state.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../../domain/models/ambassador_models.dart';
import '../providers/ambassador_notifier.dart';

// ============================================================================
// Root scaffold with bottom navigation
// ============================================================================

class AmbassadorHomeScreen extends ConsumerStatefulWidget {
  const AmbassadorHomeScreen({super.key});

  @override
  ConsumerState<AmbassadorHomeScreen> createState() =>
      _AmbassadorHomeScreenState();
}

class _AmbassadorHomeScreenState
    extends ConsumerState<AmbassadorHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tab,
        children: const [
          _AmbassadorHomeTab(),
          _ReferralTab(),
          PlaceholderTab(
            icon: Icons.bar_chart_outlined,
            title: 'Mes Rapports',
            subtitle:
                'Scores, niveaux de risque et recommandations — bientôt disponible',
          ),
          SharedProfileTab(
            extraTiles: [
              _AmbassadorProfileTile(),
            ],
          ),
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
            icon: Icons.group_outlined,
            activeIcon: Icons.group_outlined,
            label: 'Parrainage',
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
// Ambassador profile tile (injected into SharedProfileTab)
// ============================================================================

class _AmbassadorProfileTile extends StatelessWidget {
  const _AmbassadorProfileTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.workspace_premium_outlined,
              color: AppColors.muted, size: 22),
          title: Text(
            'Mon espace ambassadeur',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.disabled, size: 20),
          onTap: () {},
        ),
        const Divider(height: 1, color: Color(0xFFF0F2F4)),
      ],
    );
  }
}

// ============================================================================
// Tab 0 — Accueil ambassador (home + role badge)
// ============================================================================

class _AmbassadorHomeTab extends ConsumerStatefulWidget {
  const _AmbassadorHomeTab();

  @override
  ConsumerState<_AmbassadorHomeTab> createState() =>
      _AmbassadorHomeTabState();
}

class _AmbassadorHomeTabState
    extends ConsumerState<_AmbassadorHomeTab>
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
    // Chargement des métriques dès l'ouverture du home tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ambassadorNotifierProvider.notifier).load();
    });
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

    // Quick metrics from notifier (null if not loaded yet)
    final ambassadorState = ref.watch(ambassadorNotifierProvider);
    final metrics = ambassadorState is AmbassadorLoaded
        ? ambassadorState.metrics
        : null;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      HomeAvatar(initial: initial),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                const SizedBox(width: 8),
                                _RoleBadge(
                                    label: metrics?.levelLabel ?? 'Ambassadeur'),
                              ],
                            ),
                            Text(
                              'Partagez, impactez, grandissez',
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
                            context.pushNamed(RouteNames.ambassadorQr),
                        tooltip: 'Scanner un QR',
                      ),
                      const SizedBox(width: 8),
                      const HomeNotificationButton(badge: 2),
                    ],
                  ),
                ),
              ),
            ),

            // ── Security gate banner ──────────────────────────────────
            if (gateRequired && user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: SecurityGateBanner(user: user),
                ),
              ),

            // ── Hero évaluation card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _AmbHeroEvalCard(gateRequired: gateRequired),
              ),
            ),

            // ── Services ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: const HomeSectionHeader(title: 'Services'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    HomeActionTile(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.accent,
                      iconBg: AppColors.accentSoft,
                      title: 'Dépistage de Proximité',
                      subtitle: 'Trouver un site près de vous',
                      onTap: () => context
                          .pushNamed(RouteNames.ambassadorDepistage),
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
                          .pushNamed(RouteNames.ambassadorConseiller),
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
// Role badge chip
// ============================================================================

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, Color(0xFF14788A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Stats strip (Total / Actifs / Inscrits)
// ============================================================================

class _StatsStrip extends StatelessWidget {
  final AmbassadorMetrics metrics;
  const _StatsStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatCell(
              label: 'Total', value: '${metrics.totalReferrals}'),
          _StatDivider(),
          _StatCell(
              label: 'Actifs',
              value: '${metrics.activeReferrals}',
              valueColor: AppColors.brand),
          _StatDivider(),
          _StatCell(
              label: 'Inscrits',
              value: '${metrics.completedUsages}',
              valueColor: AppColors.support),
          if (metrics.badgesEarned > 0) ...[
            _StatDivider(),
            _StatCell(
                label: 'Badges',
                value: '${metrics.badgesEarned}',
                icon: Icons.military_tech_rounded,
                valueColor: AppColors.warning),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: valueColor ?? AppColors.foreground)
          else
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor ?? AppColors.foreground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (icon != null)
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: valueColor ?? AppColors.foreground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.brand.withValues(alpha: 0.15),
    );
  }
}

// ============================================================================
// Ambassador hero card — même design que la bénéficiaire
// ============================================================================

// Provider local (miroir de celui du bénéficiaire)
class _AmbEvalSummary {
  final double progress;
  final bool hasStarted;
  final bool isComplete;
  const _AmbEvalSummary({
    required this.progress,
    required this.hasStarted,
    required this.isComplete,
  });
}

final _ambEvalSummaryProvider = FutureProvider<_AmbEvalSummary>((ref) async {
  final live = ref.watch(evaluationNotifierProvider);
  if (live is EvaluationActive) {
    return _AmbEvalSummary(
        progress: live.progress, hasStarted: true, isComplete: false);
  }
  if (live is EvaluationComplete) {
    return const _AmbEvalSummary(
        progress: 1.0, hasStarted: true, isComplete: true);
  }
  final stored = await ref.read(evaluationLocalDatasourceProvider).load();
  if (stored == null) {
    return const _AmbEvalSummary(
        progress: 0.0, hasStarted: false, isComplete: false);
  }
  if (stored.isComplete) {
    return const _AmbEvalSummary(
        progress: 1.0, hasStarted: true, isComplete: true);
  }
  final answered = stored.answers.length;
  final total = stored.questionHistory.isNotEmpty
      ? stored.questionHistory.last.totalSteps
      : null;
  final progress = total != null && total > 0
      ? (answered / total).clamp(0.0, 1.0)
      : (answered > 0 ? 0.05 : 0.0);
  return _AmbEvalSummary(
    progress: progress,
    hasStarted: stored.sessionId != null,
    isComplete: false,
  );
});

class _AmbHeroEvalCard extends ConsumerStatefulWidget {
  final bool gateRequired;
  const _AmbHeroEvalCard({this.gateRequired = false});

  @override
  ConsumerState<_AmbHeroEvalCard> createState() => _AmbHeroEvalCardState();
}

class _AmbHeroEvalCardState extends ConsumerState<_AmbHeroEvalCard>
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
    final summaryAsync = ref.watch(_ambEvalSummaryProvider);
    final summary = summaryAsync.valueOrNull ??
        const _AmbEvalSummary(
            progress: 0.0, hasStarted: false, isComplete: false);

    final authVal = ref.watch(authNotifierProvider).valueOrNull;
    final gateToken = authVal is AuthStateAuthenticated
        ? authVal.user.token
        : null;

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
                                ? Icons.check_circle_outline_rounded
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
                              'Mon Évaluation',
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
                              'Comprendre mes symptômes et risques',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
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
                    _AmbLockedCta(token: gateToken)
                  else if (summary.isComplete)
                    _AmbEvalDoneCta()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .goNamed(RouteNames.beneficiaryEvaluation),
                        icon: Icon(
                          summary.hasStarted
                              ? Icons.arrow_forward_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(
                          summary.hasStarted
                              ? 'Continuer l\'évaluation'
                              : 'Démarrer l\'évaluation',
                        ),
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

class _AmbEvalDoneCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Évaluation complétée',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AmbLockedCta extends ConsumerWidget {
  final String? token;
  const _AmbLockedCta({required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: token == null
          ? null
          : () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) =>
                      _AmbPinSetupWrapper(sessionToken: token!),
                ),
              ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                color: Colors.white, size: 18),
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

class _AmbPinSetupWrapper extends ConsumerWidget {
  final String sessionToken;
  const _AmbPinSetupWrapper({required this.sessionToken});

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
// Tab 1 — Parrainage
// ============================================================================

class _ReferralTab extends ConsumerStatefulWidget {
  const _ReferralTab();

  @override
  ConsumerState<_ReferralTab> createState() => _ReferralTabState();
}

class _ReferralTabState extends ConsumerState<_ReferralTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ambassadorNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ambassadorNotifierProvider);

    return SafeArea(
      child: switch (state) {
        AmbassadorLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          ),
        AmbassadorError(:final message) => _ErrorBody(
            message: message,
            onRetry: () =>
                ref.read(ambassadorNotifierProvider.notifier).load(),
          ),
        AmbassadorLoaded() => _ReferralBody(
            state: state,
            onRevoke: (id) => ref
                .read(ambassadorNotifierProvider.notifier)
                .revokeReferral(id),
            onRefresh: () =>
                ref.read(ambassadorNotifierProvider.notifier).load(),
          ),
      },
    );
  }
}

// ============================================================================
// Referral body (loaded state)
// ============================================================================

class _ReferralBody extends StatelessWidget {
  final AmbassadorLoaded state;
  final void Function(String id) onRevoke;
  final Future<void> Function() onRefresh;

  const _ReferralBody({
    required this.state,
    required this.onRevoke,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parrainage',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Invitez vos contacts à rejoindre CheReh',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  // Icône pour ouvrir le modal de génération
                  Tooltip(
                    message: 'Générer un lien',
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _GenerateLinkModal(),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_link_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats strip (Total / Actifs / Inscrits) ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _StatsStrip(metrics: state.metrics),
            ),
          ),

          // ── Level card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _LevelCard(metrics: state.metrics),
            ),
          ),

          // ── Referrals list ───────────────────────────────────────────
          if (state.referrals.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: HomeSectionHeader(
                  title: 'Mes liens (${state.referrals.length})',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverList.separated(
                itemCount: state.referrals.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, i) => _ReferralTile(
                  referral: state.referrals[i],
                  onRevoke: () => onRevoke(state.referrals[i].id),
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }
}

// ============================================================================
// Level card
// ============================================================================

const _levelOrder = ['starter', 'bronze', 'silver', 'gold', 'platinum'];

Color _levelColor(String code) => switch (code) {
      'starter' => AppColors.muted,
      'bronze' => const Color(0xFFCD7F32),
      'silver' => const Color(0xFF8E9EAD),
      'gold' => AppColors.warning,
      'platinum' => AppColors.brand,
      _ => AppColors.muted,
    };

class _LevelCard extends StatelessWidget {
  final AmbassadorMetrics metrics;
  const _LevelCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final idx = _levelOrder.indexOf(metrics.levelCode);
    final progress = idx < 0 ? 0.0 : (idx + 1) / _levelOrder.length;
    final nextLevel = idx >= 0 && idx < _levelOrder.length - 1
        ? _levelOrder[idx + 1]
        : null;
    final color = _levelColor(metrics.levelCode);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau ${metrics.levelLabel}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    if (nextLevel != null)
                      Text(
                        'Prochain : ${_levelLabel(nextLevel)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              if (metrics.badgesEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${metrics.badgesEarned}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatPill(label: 'Liens créés',
                  value: '${metrics.totalReferrals}'),
              _StatPill(label: 'Actifs',
                  value: '${metrics.activeReferrals}',
                  highlight: true),
              _StatPill(label: 'Inscrits',
                  value: '${metrics.completedUsages}',
                  highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  static String _levelLabel(String code) => switch (code) {
        'starter' => 'Débutant',
        'bronze' => 'Bronze',
        'silver' => 'Argent',
        'gold' => 'Or',
        'platinum' => 'Platine',
        _ => code,
      };
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatPill(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.brand : AppColors.foreground,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

// ============================================================================
// Generate link — bottom sheet modal (ConsumerStatefulWidget)
// ============================================================================

class _GenerateLinkModal extends ConsumerStatefulWidget {
  const _GenerateLinkModal();

  @override
  ConsumerState<_GenerateLinkModal> createState() => _GenerateLinkModalState();
}

class _GenerateLinkModalState extends ConsumerState<_GenerateLinkModal> {
  String? _selectedChannel;

  static const _channels = [
    (value: 'whatsapp', label: 'WhatsApp', icon: Icons.chat_outlined),
    (value: 'sms', label: 'SMS', icon: Icons.sms_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ambassadorNotifierProvider);
    final isGenerating =
        state is AmbassadorLoaded ? state.isGenerating : false;
    final generated =
        state is AmbassadorLoaded ? state.lastGenerated : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.add_link_rounded,
                    color: AppColors.brand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Générer un lien',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Partagez avec vos contacts',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (generated?.remainingWeekly != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${generated!.remainingWeekly} restant${generated.remainingWeekly! > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Channel selector
          Row(
            children: _channels.map((ch) {
              final isSelected = _selectedChannel == ch.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedChannel = ch.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandSoft
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brand
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            ch.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ch.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Lien généré
          if (generated != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 16, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      generated.url,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.foreground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: generated.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lien copié !'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.copy_rounded,
                          size: 16, color: AppColors.brand),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Boutons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isGenerating
                      ? null
                      : () => ref
                          .read(ambassadorNotifierProvider.notifier)
                          .generateLink(channel: _selectedChannel),
                  icon: isGenerating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_link_rounded, size: 18),
                  label: Text(generated != null ? 'Régénérer' : 'Générer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (generated != null) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: generated.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lien copié : ${generated.url}'),
                        action: SnackBarAction(
                            label: 'OK', onPressed: () {}),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Referral tile
// ============================================================================

class _ReferralTile extends StatelessWidget {
  final ReferralModel referral;
  final VoidCallback onRevoke;
  const _ReferralTile({required this.referral, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = referral.isRevoked
        ? (AppColors.muted, 'Révoqué', Icons.block_outlined)
        : referral.isExpired
            ? (AppColors.warning, 'Expiré', Icons.schedule_outlined)
            : (AppColors.support, 'Actif', Icons.check_circle_outline);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.link_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.foreground,
                  ),
                ),
                if (referral.channel != null)
                  Text(
                    referral.channel!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (referral.isActive) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _confirmRevoke(context),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.block_outlined,
                    size: 18, color: AppColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Révoquer ce lien\u00a0?'),
        content: const Text(
            'Ce lien ne pourra plus être utilisé pour rejoindre CheReh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRevoke();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Error body
// ============================================================================

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 30, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
