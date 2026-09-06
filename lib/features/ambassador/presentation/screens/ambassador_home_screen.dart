import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../beneficiary/data/datasources/evaluation_local_datasource.dart';
import '../../../beneficiary/data/datasources/evaluation_remote_datasource.dart';
import '../../../beneficiary/presentation/providers/evaluation_notifier.dart';
import '../../../beneficiary/presentation/providers/evaluation_state.dart';
import '../../../beneficiary/presentation/screens/reports_tab_screen.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../../../evaluator/domain/models/beneficiary_summary.dart';
import '../../../evaluator/presentation/widgets/beneficiary_directory_view.dart';

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
          _AmbMonSuiviTab(),
          _AmbBeneficiariesTab(),
          ReportsTabScreen(),
          SharedProfileTab(
            extraTiles: [_AmbassadorProfileTile()],
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
            icon: Icons.favorite_border_rounded,
            activeIcon: Icons.favorite_rounded,
            label: 'Mon suivi',
            active: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
          HomeNavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
            label: 'Bénéficiaires',
            active: _tab == 2,
            onTap: () => setState(() => _tab = 2),
          ),
          HomeNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Rapports',
            active: _tab == 3,
            onTap: () => setState(() => _tab = 3),
          ),
          HomeNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
            active: _tab == 4,
            onTap: () => setState(() => _tab = 4),
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
                                const _RoleBadge(label: 'Ambassadeur'),
                              ],
                            ),
                            Text(
                              "Accompagnez les femmes de votre communauté",
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
                    _AmbContinueDiscussionCta()
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

class _AmbContinueDiscussionCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.goNamed(RouteNames.beneficiaryEvaluation),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: const Text('Continuer la discussion'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brand,
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
// Tab 1 — Mon suivi (thématiques)
// ============================================================================

class _AmbMonSuiviTab extends ConsumerWidget {
  const _AmbMonSuiviTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocsAsync = ref.watch(thematicBlocsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
              data: (blocs) => Column(
                children: blocs
                    .map((bloc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AmbSuiviCard(bloc: bloc),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _AmbSuiviCard extends ConsumerWidget {
  final ThematicBlocDto bloc;
  const _AmbSuiviCard({required this.bloc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref
              .read(evaluationNotifierProvider.notifier)
              .startThematic(bloc.key);
          context.goNamed(RouteNames.beneficiaryEvaluation);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF4F6F8), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _ambIconFromString(bloc.icon),
                  color: AppColors.brand,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloc.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
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

IconData _ambIconFromString(String? name) => switch (name) {
      // Material names
      'water_drop' => Icons.water_drop_outlined,
      'favorite' => Icons.favorite_border_rounded,
      'medical_services' => Icons.medical_services_outlined,
      'calendar_month' => Icons.calendar_month_outlined,
      'self_improvement' => Icons.self_improvement_outlined,
      'vaccines' => Icons.vaccines_outlined,
      'monitor_heart' => Icons.monitor_heart_outlined,
      'nightlight' => Icons.nightlight_outlined,
      'psychology' => Icons.psychology_outlined,
      'health_and_safety' => Icons.health_and_safety_outlined,
      // Lucide/Heroicon names (backend)
      'heart' => Icons.favorite_border_rounded,
      'shield' => Icons.shield_outlined,
      'user' => Icons.person_outline_rounded,
      'users' => Icons.group_outlined,
      'activity' => Icons.show_chart_rounded,
      'clipboard' => Icons.assignment_outlined,
      'calendar' => Icons.calendar_month_outlined,
      'search' => Icons.search_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };

// ============================================================================
// Tab 2 — Bénéficiaires
// ============================================================================

/// Les bénéficiaires suivies par l'ambassadeur, et l'entrée vers leur
/// évaluation.
///
/// Même composant que l'onglet Patients de l'agent de terrain : les deux rôles
/// conduisent le même parcours, seul l'espace qui l'héberge diffère.
class _AmbBeneficiariesTab extends StatelessWidget {
  const _AmbBeneficiariesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BeneficiaryDirectoryView(
        header: const _AmbBeneficiariesHeader(),
        onSelect: (beneficiary) => _openEvaluation(context, beneficiary),
      ),
    );
  }

  /// C'est le serveur qui décide s'il s'agit d'un démarrage ou de la reprise
  /// d'une session laissée ouverte lors d'une visite précédente.
  void _openEvaluation(BuildContext context, BeneficiarySummary beneficiary) {
    context.goNamed(
      RouteNames.beneficiaryEvaluation,
      extra: beneficiary.identityId,
    );
  }
}

class _AmbBeneficiariesHeader extends StatelessWidget {
  const _AmbBeneficiariesHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bénéficiaires',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Ouvrez une évaluation ou reprenez une visite',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
