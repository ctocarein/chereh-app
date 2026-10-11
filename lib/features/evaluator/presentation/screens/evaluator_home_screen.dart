import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../data/datasources/beneficiary_directory_datasource.dart';
import '../providers/beneficiary_directory_notifier.dart';
import '../widgets/evaluator_dashboard_tab.dart';
import '../widgets/evaluator_patients_tab.dart';
import '../widgets/health_facilities_tab.dart';

/// L'espace de celles et ceux qui évaluent pour les autres — agent de terrain
/// ou ambassadrice.
///
/// Mêmes onglets pour les deux rôles : seuls le badge, le scan QR et
/// l'enregistrement par téléphone dépendent du rôle.
class EvaluatorHomeScreen extends ConsumerStatefulWidget {
  const EvaluatorHomeScreen({super.key});

  @override
  ConsumerState<EvaluatorHomeScreen> createState() =>
      _EvaluatorHomeScreenState();
}

class _EvaluatorHomeScreenState extends ConsumerState<EvaluatorHomeScreen> {
  int _tab = 0;

  /// Bascule sur la liste, déjà filtrée : la carte « À suivre » de l'accueil
  /// mène aux patientes qu'elle compte.
  void _openPatients(DirectoryFilter filter) {
    ref.read(beneficiaryDirectoryProvider.notifier).setFilter(filter);
    setState(() => _tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tab,
        children: [
          EvaluatorDashboardTab(onOpenPatients: _openPatients),
          const EvaluatorPatientsTab(),
          const HealthFacilitiesTab(),
          const SharedProfileTab(),
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
            activeIcon: Icons.group_rounded,
            label: 'Patients',
            active: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
          HomeNavItem(
            icon: Icons.local_hospital_outlined,
            activeIcon: Icons.local_hospital_rounded,
            label: 'Hôpitaux',
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
