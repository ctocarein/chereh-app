import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/home_shared_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/beneficiary_directory_datasource.dart';
import '../evaluator_navigation.dart';
import '../providers/beneficiary_directory_notifier.dart';
import '../widgets/evaluator_dashboard_tab.dart';
import '../widgets/evaluator_patients_tab.dart';
import '../widgets/health_facility_directory.dart';

/// Comment on arrive sur l'espace évaluateur — passé en `extra` de la route.
///
/// Au retour d'une évaluation, on reprend sur la liste des patientes avec un
/// mot de confirmation : l'évaluateur enchaîne sur la suivante sans détour.
class EvaluatorHomeArrival {
  final int tab;
  final String? message;

  /// Propose d'ouvrir aussitôt une nouvelle évaluation depuis le message.
  final bool offerNextEvaluation;

  const EvaluatorHomeArrival({
    this.tab = 0,
    this.message,
    this.offerNextEvaluation = false,
  });

  static EvaluatorHomeArrival? fromExtra(Object? extra) =>
      extra is EvaluatorHomeArrival ? extra : null;
}

/// L'espace de celles et ceux qui évaluent pour les autres — agent de terrain
/// ou ambassadrice.
///
/// Mêmes onglets pour les deux rôles : seuls le badge, le scan QR et
/// l'enregistrement par téléphone dépendent du rôle.
class EvaluatorHomeScreen extends ConsumerStatefulWidget {
  static const patientsTab = 1;

  final EvaluatorHomeArrival? arrival;

  const EvaluatorHomeScreen({super.key, this.arrival});

  @override
  ConsumerState<EvaluatorHomeScreen> createState() =>
      _EvaluatorHomeScreenState();
}

class _EvaluatorHomeScreenState extends ConsumerState<EvaluatorHomeScreen> {
  late int _tab = widget.arrival?.tab ?? 0;

  @override
  void initState() {
    super.initState();
    final arrival = widget.arrival;
    final message = arrival?.message;
    if (message == null) return;

    // Après la première frame : le Scaffold doit exister pour porter le message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: arrival!.offerNextEvaluation
              ? SnackBarAction(
                  label: 'Nouvelle évaluation',
                  textColor: AppColors.brandSoft,
                  // Le message survit à la navigation : l'écran a pu être
                  // quitté entre-temps.
                  onPressed: () {
                    if (mounted) startNewBeneficiaryEvaluation(context);
                  },
                )
              : null,
        ),
      );
    });
  }

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
          const HealthFacilityDirectory(
            title: 'Hôpitaux',
            subtitle: 'Où orienter une patiente après son évaluation',
          ),
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
