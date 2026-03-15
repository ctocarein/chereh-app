import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../../../beneficiary/data/datasources/evaluation_local_datasource.dart';
import '../../../beneficiary/presentation/providers/evaluation_notifier.dart';
import '../../../beneficiary/presentation/providers/evaluation_state.dart';
import '../../domain/models/beneficiary_registration.dart';
import '../providers/field_agent_notifier.dart';

// ============================================================================
// Root scaffold with bottom navigation
// ============================================================================

class FieldAgentHomeScreen extends ConsumerStatefulWidget {
  const FieldAgentHomeScreen({super.key});

  @override
  ConsumerState<FieldAgentHomeScreen> createState() =>
      _FieldAgentHomeScreenState();
}

class _FieldAgentHomeScreenState extends ConsumerState<FieldAgentHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tab,
        children: [
          _AgentHomeTab(onSwitchToPatients: () => setState(() => _tab = 1)),
          const _PatientsTab(),
          PlaceholderTab(
            icon: Icons.bar_chart_outlined,
            title: 'Mes Rapports',
            subtitle:
                'Scores, niveaux de risque et recommandations — bientôt disponible',
          ),
          SharedProfileTab(extraTiles: [_AgentProfileTile()]),
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
            icon: Icons.group_add_outlined,
            activeIcon: Icons.group_add_rounded,
            label: 'Patients',
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
// Agent profile tile (injected into SharedProfileTab)
// ============================================================================

class _AgentProfileTile extends StatelessWidget {
  const _AgentProfileTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(
            Icons.medical_services_outlined,
            color: AppColors.muted,
            size: 22,
          ),
          title: Text(
            'Mon espace agent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.disabled,
            size: 20,
          ),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Espace agent — bientôt disponible'),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F2F4)),
      ],
    );
  }
}

// ============================================================================
// Tab 0 — Accueil (evaluation card + agent quick actions)
// ============================================================================

class _AgentHomeTab extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToPatients;
  const _AgentHomeTab({required this.onSwitchToPatients});

  @override
  ConsumerState<_AgentHomeTab> createState() => _AgentHomeTabState();
}

class _AgentHomeTabState extends ConsumerState<_AgentHomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
            // ── Top bar ──────────────────────────────────────────────
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
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.foreground,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const _AgentBadge(),
                              ],
                            ),
                            Text(
                              'Accompagnez vos patients aujourd\'hui',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
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

            // ── Quick actions strip ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _QuickActionsStrip(
                  onNewPatient: widget.onSwitchToPatients,
                  onAssistedEval: () =>
                      context.goNamed(RouteNames.fieldAgentAssistedEval),
                  onHistory: widget.onSwitchToPatients,
                  onQrPatient: () => context.goNamed(RouteNames.fieldAgentQr),
                ),
              ),
            ),

            // ── Personal evaluation card ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PersonalEvalCard(gateRequired: gateRequired),
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
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Dépistage de proximité — bientôt disponible',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    HomeActionTile(
                      icon: Icons.support_agent_outlined,
                      iconColor: AppColors.support,
                      iconBg: const Color(0xFFD4F5E5),
                      title: 'Parler À Un Conseiller',
                      subtitle: 'Consultation ou rendez-vous médical',
                      badge: 'Premium',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Conseiller médical — bientôt disponible',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
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
// Agent role badge
// ============================================================================

class _AgentBadge extends StatelessWidget {
  const _AgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.support.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.support.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_services_rounded,
            color: AppColors.support,
            size: 11,
          ),
          SizedBox(width: 3),
          Text(
            'Agent de terrain',
            style: TextStyle(
              color: AppColors.support,
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
// Quick actions strip (shortcuts to key agent tasks)
// ============================================================================

class _QuickActionsStrip extends StatelessWidget {
  final VoidCallback onNewPatient;
  final VoidCallback onAssistedEval;
  final VoidCallback onHistory;
  final VoidCallback onQrPatient;

  const _QuickActionsStrip({
    required this.onNewPatient,
    required this.onAssistedEval,
    required this.onHistory,
    required this.onQrPatient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.person_add_outlined,
          label: 'Nouveau\npatient',
          color: AppColors.brand,
          bg: AppColors.brandSoft,
          onTap: onNewPatient,
        ),
        const SizedBox(width: 10),
        _QuickAction(
          icon: Icons.assignment_outlined,
          label: 'Éval.\nassistée',
          color: const Color(0xFF7B5EA7),
          bg: const Color(0xFFF0EBF8),
          onTap: onAssistedEval,
        ),
        const SizedBox(width: 10),
        _QuickAction(
          icon: Icons.history_outlined,
          label: 'Historique\npatients',
          color: AppColors.warning,
          bg: const Color(0xFFFFF8E6),
          onTap: onHistory,
        ),
        const SizedBox(width: 10),
        _QuickAction(
          icon: Icons.qr_code_2_outlined,
          label: 'Scanner\nPatient',
          color: AppColors.accent,
          bg: AppColors.accentSoft,
          onTap: onQrPatient,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Personal evaluation card — full hero version (mirrors beneficiary/ambassador)
// ============================================================================

class _AgentEvalSummary {
  final double progress;
  final bool hasStarted;
  final bool isComplete;
  const _AgentEvalSummary({
    required this.progress,
    required this.hasStarted,
    required this.isComplete,
  });
}

final _agentEvalSummaryProvider = FutureProvider<_AgentEvalSummary>((
  ref,
) async {
  final live = ref.watch(evaluationNotifierProvider);
  if (live is EvaluationActive) {
    return _AgentEvalSummary(
      progress: live.progress,
      hasStarted: true,
      isComplete: false,
    );
  }
  if (live is EvaluationComplete) {
    return const _AgentEvalSummary(
      progress: 1.0,
      hasStarted: true,
      isComplete: true,
    );
  }
  final stored = await ref.read(evaluationLocalDatasourceProvider).load();
  if (stored == null) {
    return const _AgentEvalSummary(
      progress: 0.0,
      hasStarted: false,
      isComplete: false,
    );
  }
  if (stored.isComplete) {
    return const _AgentEvalSummary(
      progress: 1.0,
      hasStarted: true,
      isComplete: true,
    );
  }
  final answered = stored.answers.length;
  final total = stored.questionHistory.isNotEmpty
      ? stored.questionHistory.last.totalSteps
      : null;
  final progress = total != null && total > 0
      ? (answered / total).clamp(0.0, 1.0)
      : (answered > 0 ? 0.05 : 0.0);
  return _AgentEvalSummary(
    progress: progress,
    hasStarted: stored.sessionId != null,
    isComplete: false,
  );
});

class _PersonalEvalCard extends ConsumerStatefulWidget {
  final bool gateRequired;
  const _PersonalEvalCard({this.gateRequired = false});

  @override
  ConsumerState<_PersonalEvalCard> createState() => _PersonalEvalCardState();
}

class _PersonalEvalCardState extends ConsumerState<_PersonalEvalCard>
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
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_agentEvalSummaryProvider);
    final summary =
        summaryAsync.valueOrNull ??
        const _AgentEvalSummary(
          progress: 0.0,
          hasStarted: false,
          isComplete: false,
        );

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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Comprendre mes symptômes et risques',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.gateRequired)
                    _AgentLockedCta(token: gateToken)
                  else if (summary.isComplete)
                    _AgentEvalDoneCta()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.goNamed(RouteNames.beneficiaryEvaluation),
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

class _AgentEvalDoneCta extends StatelessWidget {
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
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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

class _AgentLockedCta extends ConsumerWidget {
  final String? token;
  const _AgentLockedCta({required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: token == null
          ? null
          : () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => _AgentPinSetupWrapper(sessionToken: token!),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentPinSetupWrapper extends ConsumerWidget {
  final String sessionToken;
  const _AgentPinSetupWrapper({required this.sessionToken});

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
// Tab 1 — Patients (register / find beneficiary)
// ============================================================================

class _PatientsTab extends ConsumerStatefulWidget {
  const _PatientsTab();

  @override
  ConsumerState<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends ConsumerState<_PatientsTab> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(fieldAgentNotifierProvider.notifier)
          .registerBeneficiary(_phoneCtrl.text.trim());
    }
  }

  void _reset() {
    ref.read(fieldAgentNotifierProvider.notifier).reset();
    _phoneCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldAgentNotifierProvider);
    final isSearching = state is FieldAgentSearching;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Enregistrez ou retrouvez un bénéficiaire',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),

          // ── Info banner ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InfoCard(
                text:
                    'Saisissez le numéro de téléphone du bénéficiaire. '
                    'S\'il n\'existe pas encore, un compte lui sera créé '
                    'automatiquement.',
              ),
            ),
          ),

          // ── Search form ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _SearchForm(
                formKey: _formKey,
                phoneCtrl: _phoneCtrl,
                isSearching: isSearching,
                onSubmit: _submit,
              ),
            ),
          ),

          // ── Result (animated) ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: switch (state) {
                FieldAgentFound(:final result) => Padding(
                  key: ValueKey(result.identityId),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ResultCard(result: result, onReset: _reset),
                ),
                FieldAgentError(:final message) => Padding(
                  key: const ValueKey('error'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ErrorCard(message: message, onRetry: _submit),
                ),
                _ => const SizedBox.shrink(key: ValueKey('idle')),
              },
            ),
          ),

          // ── Reset link ───────────────────────────────────────────────
          if (state is! FieldAgentIdle)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Nouvelle recherche'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ============================================================================
// Search form card
// ============================================================================

class _SearchForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final bool isSearching;
  final VoidCallback onSubmit;

  const _SearchForm({
    required this.formKey,
    required this.phoneCtrl,
    required this.isSearching,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Rechercher un bénéficiaire',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '699 000 000',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Text(
                    '🇨🇲 +237',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.brand,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Numéro invalide (8 chiffres minimum)'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSearching ? null : onSubmit,
              icon: isSearching
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 18),
              label: Text(
                isSearching
                    ? 'Recherche en cours…'
                    : 'Rechercher / Enregistrer',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Result card (new or existing patient)
// ============================================================================

class _ResultCard extends StatelessWidget {
  final BeneficiaryRegistration result;
  final VoidCallback onReset;

  const _ResultCard({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final isNew = result.isNew;
    final color = isNew ? AppColors.support : AppColors.brand;
    final bg = isNew ? const Color(0xFFD4F5E5) : AppColors.brandSoft;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Status header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(
                    isNew ? Icons.person_add_rounded : Icons.person_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNew
                            ? 'Nouveau bénéficiaire créé'
                            : 'Bénéficiaire trouvé',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        result.phone,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        isNew ? 'Créé' : 'Trouvé',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Identity + CTA ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID\u00a0: ',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                      Expanded(
                        child: Text(
                          result.identityId,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Évaluation assistée — disponible prochainement.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Démarrer l\'évaluation assistée'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Error card
// ============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une erreur est survenue',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Info card
// ============================================================================

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.brand, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.brandStrong,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
