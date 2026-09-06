import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/datasources/beneficiary_directory_datasource.dart';
import '../../domain/models/beneficiary_summary.dart';

final beneficiaryDirectoryProvider = NotifierProvider<BeneficiaryDirectoryNotifier,
    BeneficiaryDirectoryState>(BeneficiaryDirectoryNotifier.new);

/// État de l'annuaire.
///
/// Un seul objet plutôt qu'une union : la liste reste affichée pendant qu'une
/// recherche ou une page suivante se charge, sinon l'écran clignote à chaque
/// frappe et l'agent perd sa place.
class BeneficiaryDirectoryState {
  final List<BeneficiarySummary> items;
  final String search;
  final DirectoryFilter filter;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  /// Vrai avant le premier chargement : distingue « pas encore chargé » de
  /// « chargé et vide », qui n'appellent pas le même message.
  final bool isInitial;

  const BeneficiaryDirectoryState({
    this.items = const [],
    this.search = '',
    this.filter = DirectoryFilter.all,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.isInitial = true,
  });

  bool get isEmpty => !isInitial && !isLoading && items.isEmpty;
  bool get isFiltered => search.trim().isNotEmpty || filter != DirectoryFilter.all;

  BeneficiaryDirectoryState copyWith({
    List<BeneficiarySummary>? items,
    String? search,
    DirectoryFilter? filter,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    bool? isInitial,
  }) =>
      BeneficiaryDirectoryState(
        items: items ?? this.items,
        search: search ?? this.search,
        filter: filter ?? this.filter,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        isInitial: isInitial ?? this.isInitial,
      );
}

class BeneficiaryDirectoryNotifier extends Notifier<BeneficiaryDirectoryState> {
  Timer? _debounce;

  /// Incrémenté à chaque nouvelle requête : une réponse tardive d'une frappe
  /// précédente ne doit pas écraser le résultat de la frappe courante.
  int _requestId = 0;

  @override
  BeneficiaryDirectoryState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const BeneficiaryDirectoryState();
  }

  /// Premier chargement. Sans effet si l'annuaire est déjà peuplé.
  Future<void> loadInitial() async {
    if (!state.isInitial) return;
    await _load(page: 1);
  }

  Future<void> refresh() => _load(page: 1);

  /// Recherche différée : on laisse l'utilisateur finir de taper.
  void search(String term) {
    _debounce?.cancel();
    state = state.copyWith(search: term);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(page: 1);
    });
  }

  void setFilter(DirectoryFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    _load(page: 1);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    await _load(page: _nextPage);
  }

  int get _nextPage => (state.items.length ~/ _perPage) + 1;

  static const _perPage = 25;

  Future<void> _load({required int page}) async {
    final isFirstPage = page == 1;
    final requestId = ++_requestId;

    state = state.copyWith(
      isLoading: isFirstPage,
      isLoadingMore: !isFirstPage,
      clearError: true,
    );

    try {
      final result = await ref.read(beneficiaryDirectoryDatasourceProvider).fetch(
            search: state.search,
            filter: state.filter,
            page: page,
            perPage: _perPage,
          );

      if (requestId != _requestId) return;

      state = state.copyWith(
        items: isFirstPage ? result.items : [...state.items, ...result.items],
        total: result.total,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
        isInitial: false,
      );
    } on ApiException catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isInitial: false,
        error: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isInitial: false,
        error: 'Impossible de charger la liste des bénéficiaires.',
      );
    }
  }
}
