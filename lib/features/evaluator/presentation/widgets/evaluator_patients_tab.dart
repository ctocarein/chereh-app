import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../field_agent/presentation/providers/field_agent_notifier.dart';
import '../../../field_agent/presentation/widgets/register_beneficiary_sheet.dart';
import '../evaluator_navigation.dart';
import '../providers/beneficiary_directory_notifier.dart';
import 'beneficiary_directory_view.dart';

/// La liste des patientes du périmètre, et l'entrée vers leur évaluation.
class EvaluatorPatientsTab extends ConsumerWidget {
  const EvaluatorPatientsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    // L'API réserve l'enregistrement par téléphone à l'agent de terrain.
    final canRegisterByPhone =
        auth is AuthStateAuthenticated && auth.user.role == UserRole.fieldAgent;

    return SafeArea(
      child: BeneficiaryDirectoryView(
        header: _PatientsHeader(
          onStartNew: () => startNewBeneficiaryEvaluation(context),
          onRegisterByPhone: canRegisterByPhone
              ? () => _openRegisterSheet(context, ref)
              : null,
        ),
        onSelect: (beneficiary) =>
            openBeneficiaryEvaluation(context, beneficiary),
        onCreate: () => startNewBeneficiaryEvaluation(context),
        createLabel: 'Démarrer une évaluation',
      ),
    );
  }

  Future<void> _openRegisterSheet(BuildContext context, WidgetRef ref) async {
    ref.read(fieldAgentNotifierProvider.notifier).reset();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const RegisterBeneficiarySheet(),
    );

    // L'enrôlement a pu créer une fiche : la liste doit la refléter.
    if (context.mounted) {
      ref.read(beneficiaryDirectoryProvider.notifier).refresh();
    }
  }
}

/// En-tête de l'onglet, glissé au-dessus de la barre de recherche.
class _PatientsHeader extends StatelessWidget {
  final VoidCallback onStartNew;
  final VoidCallback? onRegisterByPhone;

  const _PatientsHeader({
    required this.onStartNew,
    required this.onRegisterByPhone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Retrouvez une patiente ou ouvrez une nouvelle évaluation',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartNew,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Démarrer une évaluation'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          // Préparer une fiche hors visite reste utile à l'agent, mais
          // secondaire : le cas courant est d'ouvrir directement l'évaluation.
          if (onRegisterByPhone != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRegisterByPhone,
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Enregistrer par téléphone'),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
