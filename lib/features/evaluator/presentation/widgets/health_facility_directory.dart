import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/health_facility_datasource.dart';
import '../../domain/models/health_facility.dart';

/// Les établissements où se faire dépister ou orienter une patiente — avec ou
/// sans mammographe.
///
/// Sert l'onglet Hôpitaux de l'évaluateur comme l'écran de dépistage de la
/// bénéficiaire ; seuls les textes et le filtre de départ changent.
class HealthFacilityDirectory extends ConsumerStatefulWidget {
  /// Titre en tête de liste ; `null` quand l'écran hôte porte déjà une barre
  /// de titre.
  final String? title;
  final String subtitle;
  final MammographyFilter initialFilter;

  const HealthFacilityDirectory({
    super.key,
    this.title,
    required this.subtitle,
    this.initialFilter = MammographyFilter.all,
  });

  @override
  ConsumerState<HealthFacilityDirectory> createState() =>
      _HealthFacilityDirectoryState();
}

class _HealthFacilityDirectoryState
    extends ConsumerState<HealthFacilityDirectory> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  late MammographyFilter _filter = widget.initialFilter;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// On laisse finir la frappe : une requête par lettre ne sert à rien.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final query = (filter: _filter, search: _search);
    final facilities = ref.watch(healthFacilitiesProvider(query));
    final theme = Theme.of(context);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => ref
            .refresh(healthFacilitiesProvider(query).future)
            .then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Nom ou commune',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Effacer',
                                onPressed: _clearSearch,
                              ),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  itemCount: MammographyFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = MammographyFilter.values[index];
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: filter == _filter,
                      onSelected: (_) => setState(() => _filter = filter),
                      selectedColor: AppColors.brandSoft,
                      labelStyle: TextStyle(
                        color: filter == _filter
                            ? AppColors.brandStrong
                            : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(
                        color: filter == _filter
                            ? AppColors.brand
                            : AppColors.surfaceAlt,
                      ),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
            ),
            ...facilities.when<List<Widget>>(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brand, strokeWidth: 2),
                  ),
                ),
              ],
              error: (_, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _CenteredMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Impossible de charger les établissements',
                    actionLabel: 'Réessayer',
                    onAction: () =>
                        ref.invalidate(healthFacilitiesProvider(query)),
                  ),
                ),
              ],
              data: (items) {
                if (items.isEmpty) {
                  final filtered =
                      _search.isNotEmpty || _filter != MammographyFilter.all;
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CenteredMessage(
                        icon: Icons.local_hospital_outlined,
                        title: filtered
                            ? 'Aucun établissement ne correspond'
                            : 'Aucun établissement pour le moment',
                        actionLabel: filtered ? 'Tout afficher' : null,
                        onAction: filtered
                            ? () {
                                _clearSearch();
                                setState(
                                    () => _filter = MammographyFilter.all);
                              }
                            : null,
                      ),
                    ),
                  ];
                }

                return [
                  if (items.any((f) => f.isSample))
                    const SliverToBoxAdapter(child: _SampleNotice()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          _FacilityCard(facility: items[index]),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Prévient que la liste contient des exemples : personne ne doit s'y rendre.
class _SampleNotice extends StatelessWidget {
  const _SampleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF0D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF8A6410), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Certains établissements sont des exemples, en attendant la '
              'liste officielle : ils n\'existent pas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8A6410),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final HealthFacility facility;

  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [facility.kindLabel, facility.location]
        .whereType<String>()
        .join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceAlt, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: facility.hasMammography
                  ? AppColors.accentSoft
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color:
                  facility.hasMammography ? AppColors.accent : AppColors.muted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
                if (facility.address != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    facility.address!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
                if (facility.phone != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.brand),
                      const SizedBox(width: 6),
                      SelectableText(
                        facility.phone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brandStrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    facility.hasMammography
                        ? const _Pill(
                            label: 'Mammographe',
                            icon: Icons.check_circle_outline_rounded,
                            color: Color(0xFF2E7D53),
                            background: Color(0xFFDDF3E7),
                          )
                        : const _Pill(
                            label: 'Sans mammographe',
                            color: AppColors.muted,
                            background: AppColors.surfaceAlt,
                          ),
                    if (facility.isSample)
                      const _Pill(
                        label: 'Exemple',
                        color: Color(0xFF8A6410),
                        background: Color(0xFFFBF0D8),
                      ),
                  ],
                ),
                // Un exemple n'existe pas : ni numéro à composer, ni lieu où
                // se rendre.
                if (!facility.isSample) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (facility.phone != null) ...[
                        _ActionButton(
                          icon: Icons.call_outlined,
                          label: 'Appeler',
                          onTap: () => _open(
                            context,
                            Uri(scheme: 'tel', path: facility.phone),
                            'Impossible de lancer l\'appel.',
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _ActionButton(
                        icon: Icons.directions_outlined,
                        label: 'Itinéraire',
                        onTap: () => _open(
                          context,
                          _directionsUri(facility),
                          'Impossible d\'ouvrir la carte.',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// L'itinéraire vers l'établissement : par ses coordonnées quand on les a,
/// sinon par son nom et sa commune.
Uri _directionsUri(HealthFacility facility) {
  if (facility.hasCoordinates) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${facility.latitude},${facility.longitude}',
    });
  }
  final place = [facility.name, facility.municipality, 'Côte d\'Ivoire']
      .whereType<String>()
      .join(', ');
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': place,
  });
}

Future<void> _open(BuildContext context, Uri uri, String failure) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text(failure), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandStrong,
        side: const BorderSide(color: AppColors.brandSoft, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.disabled),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
