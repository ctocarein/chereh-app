import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/beneficiary_directory_datasource.dart';
import '../../data/datasources/evaluator_impact_datasource.dart';
import '../evaluator_navigation.dart';
import 'beneficiary_directory_view.dart';

/// L'accueil de l'évaluateur : où il en est, et ce qu'il a fait récemment.
class EvaluatorDashboardTab extends ConsumerWidget {
  /// Ouvre l'onglet Patients avec ce filtre.
  final ValueChanged<DirectoryFilter> onOpenPatients;

  const EvaluatorDashboardTab({super.key, required this.onOpenPatients});

  Future<void> _refresh(WidgetRef ref) async {
    // Les erreurs restent portées par les providers, qui les affichent.
    await Future.wait<Object>([
      ref.refresh(evaluatorImpactProvider.future),
      ref.refresh(recentBeneficiariesProvider.future),
    ]).catchError((_) => <Object>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final user = auth is AuthStateAuthenticated ? auth.user : null;
    final recent = ref.watch(recentBeneficiariesProvider);

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _TopBar(user: user)),

          if (user != null && user.gateRequired)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SecurityGateBanner(user: user),
              ),
            ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _StartEvaluationCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: HomeSectionHeader(title: 'Tableau de bord'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _KpiRow(onOpenPatients: onOpenPatients),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: HomeSectionHeader(
                title: 'Activité récente',
                actionLabel: 'Voir tout',
                onAction: () => onOpenPatients(DirectoryFilter.all),
              ),
            ),
          ),
          ...recent.when<List<Widget>>(
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ],
            error: (_, _) => [
              SliverToBoxAdapter(
                child: _InlineMessage(
                  icon: Icons.cloud_off_outlined,
                  text: 'Impossible de charger l\'activité récente.',
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(recentBeneficiariesProvider),
                ),
              ),
            ],
            data: (page) {
              // Les fiches jamais évaluées n'ont pas d'activité à montrer.
              final items = page.items
                  .where((b) => b.lastEvaluation != null)
                  .take(5)
                  .toList();

              if (items.isEmpty) {
                return [
                  const SliverToBoxAdapter(
                    child: _InlineMessage(
                      icon: Icons.history_rounded,
                      text: 'Aucune évaluation pour l\'instant. '
                          'Vos dernières visites apparaîtront ici.',
                    ),
                  ),
                ];
              }

              return [
                SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 84,
                    color: Color(0xFFF0F2F4),
                  ),
                  itemBuilder: (context, index) => BeneficiaryTile(
                    beneficiary: items[index],
                    onTap: () =>
                        openBeneficiaryEvaluation(context, items[index]),
                  ),
                ),
              ];
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ============================================================================
// En-tête : salutation, rôle, scan QR
// ============================================================================

class _TopBar extends StatelessWidget {
  final AuthUser? user;

  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '';
    final firstName = name.split(' ').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isFieldAgent = user?.role == UserRole.fieldAgent;

    return SafeArea(
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
                  Text(
                    firstName.isEmpty ? 'Bonjour !' : 'Bonjour, $firstName !',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                  ),
                  const SizedBox(height: 3),
                  _RoleBadge(
                    label: isFieldAgent ? 'Agent de terrain' : 'Ambassadrice',
                  ),
                ],
              ),
            ),
            HomeIconButton(
              icon: Icons.qr_code_scanner_outlined,
              tooltip: 'Scanner un QR',
              // L'agent scanne pour ouvrir l'évaluation de la patiente ;
              // l'ambassadrice garde son code et le scan de rattachement.
              onTap: () => isFieldAgent
                  ? context.goNamed(RouteNames.fieldAgentQr)
                  : context.pushNamed(RouteNames.ambassadorQr),
            ),
            const SizedBox(width: 8),
            const HomeNotificationButton(badge: 0),
          ],
        ),
      ),
    );
  }
}

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
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Démarrer une évaluation
// ============================================================================

class _StartEvaluationCard extends StatelessWidget {
  const _StartEvaluationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, Color(0xFF14788A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.health_and_safety_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelle évaluation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'La fiche de la patiente se crée pendant la visite.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => startNewBeneficiaryEvaluation(context),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Démarrer une évaluation'),
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
    );
  }
}

// ============================================================================
// Tableau de bord : évaluées, total, à suivre
// ============================================================================

class _KpiRow extends ConsumerWidget {
  final ValueChanged<DirectoryFilter> onOpenPatients;

  const _KpiRow({required this.onOpenPatients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(evaluatorImpactProvider);
    final recent = ref.watch(recentBeneficiariesProvider);

    String show(AsyncValue<int> value) => value.when(
          data: (v) => '$v',
          loading: () => '…',
          error: (_, _) => '—',
        );

    final evaluated = impact.whenData((i) => i.womenEvaluated);
    final toFollow = impact.whenData((i) => i.womenToFollow);
    final total = recent.whenData((p) => p.total);
    final hasError = impact.hasError || recent.hasError;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.task_alt_rounded,
                  value: show(evaluated),
                  label: 'Patientes évaluées',
                  color: AppColors.brandStrong,
                  background: AppColors.brandSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.groups_outlined,
                  value: show(total),
                  label: 'Patientes au total',
                  color: AppColors.foreground,
                  background: AppColors.surfaceAlt,
                  onTap: () => onOpenPatients(DirectoryFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.flag_outlined,
                  value: show(toFollow),
                  label: 'À suivre',
                  color: AppColors.accent,
                  background: AppColors.accentSoft,
                  onTap: () => onOpenPatients(DirectoryFilter.toFollow),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          _InlineMessage(
            icon: Icons.cloud_off_outlined,
            text: 'Chiffres indisponibles pour le moment.',
            actionLabel: 'Réessayer',
            onAction: () {
              ref.invalidate(evaluatorImpactProvider);
              ref.invalidate(recentBeneficiariesProvider);
            },
            padding: const EdgeInsets.only(top: 10),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const Spacer(),
                  // Le chevron dit ce qui s'ouvre ; une carte sans action n'en
                  // porte pas.
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        color: color.withValues(alpha: 0.6), size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.2,
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
// Message en ligne : vide, erreur
// ============================================================================

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  const _InlineMessage({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, color: AppColors.disabled, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
