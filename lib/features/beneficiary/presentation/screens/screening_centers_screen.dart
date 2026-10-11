import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../evaluator/data/datasources/health_facility_datasource.dart';
import '../../../evaluator/presentation/widgets/health_facility_directory.dart';

/// Où se faire dépister près de chez soi.
///
/// S'ouvre sur les établissements équipés d'un mammographe : c'est ce que
/// cherche une femme à qui son bilan recommande un examen.
class ScreeningCentersScreen extends StatelessWidget {
  const ScreeningCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dépistage de proximité'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: const HealthFacilityDirectory(
        subtitle: 'Où passer une mammographie ou consulter',
        initialFilter: MammographyFilter.available,
      ),
    );
  }
}
