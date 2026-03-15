import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/report_remote_datasource.dart';

/// FutureProvider — récupère les 5 bilans les plus récents (home card).
final recentBilansProvider = FutureProvider<List<ReportSummary>>((ref) async {
  final ds = ref.watch(reportRemoteDatasourceProvider);
  final reports = await ds.getReports();
  return reports.take(5).toList();
});

/// FutureProvider — récupère tous les bilans du bénéficiaire (liste complète).
final allBilansProvider = FutureProvider<List<ReportSummary>>((ref) async {
  return ref.watch(reportRemoteDatasourceProvider).getReports();
});
