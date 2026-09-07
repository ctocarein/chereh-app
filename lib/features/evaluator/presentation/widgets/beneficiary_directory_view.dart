import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/beneficiary_directory_datasource.dart';
import '../../domain/models/beneficiary_summary.dart';
import '../providers/beneficiary_directory_notifier.dart';

/// Annuaire des bénéficiaires, partagé par l'agent de terrain et l'ambassadeur.
///
/// Le composant ne décide pas de ce qui se passe au choix d'une bénéficiaire :
/// chaque espace branche son propre [onSelect] — ouvrir une évaluation, la
/// reprendre, consulter une fiche.
class BeneficiaryDirectoryView extends ConsumerStatefulWidget {
  /// Appelé quand l'utilisateur choisit une bénéficiaire dans la liste.
  final void Function(BeneficiarySummary beneficiary) onSelect;

  /// Action proposée quand l'annuaire est vide et sans filtre — typiquement
  /// « enregistrer une bénéficiaire ». Optionnelle.
  final VoidCallback? onCreate;
  final String createLabel;

  /// Inséré au-dessus de la barre de recherche : titre d'écran, encart…
  final Widget? header;

  const BeneficiaryDirectoryView({
    super.key,
    required this.onSelect,
    this.onCreate,
    this.createLabel = 'Enregistrer une bénéficiaire',
    this.header,
  });

  @override
  ConsumerState<BeneficiaryDirectoryView> createState() =>
      _BeneficiaryDirectoryViewState();
}

class _BeneficiaryDirectoryViewState
    extends ConsumerState<BeneficiaryDirectoryView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Après la première frame : lire un provider pendant initState est interdit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beneficiaryDirectoryProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final remaining = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
    if (remaining < 320) {
      ref.read(beneficiaryDirectoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(beneficiaryDirectoryProvider);
    final notifier = ref.read(beneficiaryDirectoryProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.brand,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _SearchField(
                controller: _searchCtrl,
                onChanged: notifier.search,
                onClear: () {
                  _searchCtrl.clear();
                  notifier.search('');
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _FilterBar(
              selected: state.filter,
              onSelect: notifier.setFilter,
            ),
          ),

          if (!state.isInitial && !state.isLoading && state.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  state.total == 1
                      ? '1 bénéficiaire'
                      : '${state.total} bénéficiaires',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ),

          if (state.error != null)
            SliverToBoxAdapter(
              child: _ErrorCard(
                message: state.error!,
                onRetry: notifier.refresh,
              ),
            ),

          if (state.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.isEmpty && state.error == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                isFiltered: state.isFiltered,
                onCreate: widget.onCreate,
                createLabel: widget.createLabel,
                onClearFilters: () {
                  _searchCtrl.clear();
                  notifier.search('');
                  notifier.setFilter(DirectoryFilter.all);
                },
              ),
            )
          else
            SliverList.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 76,
                endIndent: 20,
              ),
              itemBuilder: (context, index) => _BeneficiaryTile(
                beneficiary: state.items[index],
                onTap: () => widget.onSelect(state.items[index]),
              ),
            ),

          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recherche
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher un nom ou un numéro',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.muted,
                  tooltip: 'Effacer',
                  onPressed: onClear,
                ),
        ),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtres
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final DirectoryFilter selected;
  final ValueChanged<DirectoryFilter> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: DirectoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = DirectoryFilter.values[index];
          final isSelected = filter == selected;
          return Center(
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onSelect(filter),
              showCheckmark: false,
              selectedColor: AppColors.brandSoft,
              backgroundColor: AppColors.surfaceAlt,
              side: BorderSide(
                color: isSelected ? AppColors.brand : Colors.transparent,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.brandStrong : AppColors.muted,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne de la liste
// ---------------------------------------------------------------------------

class _BeneficiaryTile extends StatelessWidget {
  final BeneficiarySummary beneficiary;
  final VoidCallback onTap;

  const _BeneficiaryTile({required this.beneficiary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evaluation = beneficiary.lastEvaluation;
    final age = beneficiary.age;

    final subtitleParts = <String>[
      if (beneficiary.name != null && beneficiary.phone != null)
        beneficiary.phone!,
      if (age != null) '$age ans',
      if (beneficiary.municipality != null) beneficiary.municipality!,
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.brandSoft,
        child: Text(
          beneficiary.initials,
          style: const TextStyle(
            color: AppColors.brandStrong,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      title: Text(
        beneficiary.displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleParts.isNotEmpty)
            Text(
              subtitleParts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          const SizedBox(height: 6),
          _EvaluationBadge(evaluation: evaluation),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.disabled,
      ),
    );
  }
}

/// Pastille d'état de la dernière évaluation.
///
/// Le niveau de risque n'apparaît que si l'API l'a renvoyé, c'est-à-dire si
/// l'utilisateur courant a lui-même conduit cette évaluation.
class _EvaluationBadge extends StatelessWidget {
  final LastEvaluation? evaluation;

  const _EvaluationBadge({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final evaluation = this.evaluation;

    if (evaluation == null) {
      return const _Pill(
        label: 'Jamais évaluée',
        color: AppColors.muted,
        background: AppColors.surfaceAlt,
      );
    }

    if (evaluation.isInProgress) {
      return const _Pill(
        label: 'Évaluation en cours',
        color: Color(0xFF8A6410),
        background: Color(0xFFFBF0D8),
        icon: Icons.pending_outlined,
      );
    }

    final risk = evaluation.riskLevel;
    final date = evaluation.relevantDate;
    final when = date == null ? null : _formatDate(date);

    if (risk != null) {
      final (color, background) = switch (risk) {
        RiskLevel.low => (const Color(0xFF2E7D53), const Color(0xFFDDF3E7)),
        RiskLevel.moderate => (const Color(0xFF8A6410), const Color(0xFFFBF0D8)),
        RiskLevel.high => (const Color(0xFF9E3A22), const Color(0xFFF9E3DD)),
      };
      return _Pill(
        label: when == null ? risk.label : '${risk.label} · $when',
        color: color,
        background: background,
      );
    }

    // Évaluation conduite par un autre évaluateur : on sait qu'elle existe,
    // pas ce qu'elle a conclu.
    final status = evaluation.status?.label ?? 'Évaluée';
    return _Pill(
      label: when == null ? status : '$status · $when',
      color: AppColors.muted,
      background: AppColors.surfaceAlt,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// États vides et erreurs
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onCreate;
  final String createLabel;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.isFiltered,
    required this.onCreate,
    required this.createLabel,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.groups_outlined,
            size: 44,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Aucune bénéficiaire ne correspond'
                : 'Aucune bénéficiaire enregistrée',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Essayez un autre nom, un autre numéro, ou retirez les filtres.'
                : 'Les bénéficiaires que vous enregistrez apparaîtront ici.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          if (isFiltered)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Retirer les filtres'),
            )
          else if (onCreate != null)
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(createLabel),
            ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3C9BE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 20, color: Color(0xFF9E3A22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF7A2E1B),
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  final now = DateTime.now();
  final month = months[date.month - 1];
  return date.year == now.year
      ? '${date.day} $month'
      : '${date.day} $month ${date.year}';
}
