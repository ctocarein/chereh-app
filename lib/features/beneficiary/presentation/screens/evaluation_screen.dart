import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/evaluation_remote_datasource.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/evaluation_session.dart';
import '../providers/evaluation_notifier.dart';
import '../providers/evaluation_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/evaluation_progress_bar.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  /// UUID de la bénéficiaire ciblée — renseigné en évaluation assistée.
  final String? subjectId;

  /// Ouvre l'évaluation pour une personne pas encore enregistrée : sa fiche est
  /// créée au démarrage, son numéro et sa commune sont demandés par le
  /// questionnaire.
  final bool newSubject;

  const EvaluationScreen({
    super.key,
    this.subjectId,
    this.newSubject = false,
  });

  /// Vrai quand l'évaluation est conduite pour un tiers.
  bool get isAssisted => subjectId != null || newSubject;

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  void _handleClose(BuildContext context, EvaluationState state) {
    // En évaluation assistée, on rend l'évaluateur à SON espace : renvoyer un
    // ambassadeur vers l'accueil de l'agent de terrain le sortirait du sien.
    if (widget.isAssisted) {
      final auth = ref.read(authNotifierProvider).valueOrNull;
      final role = auth is AuthStateAuthenticated ? auth.user.role : null;
      context.goNamed(
        role == UserRole.ambassador
            ? RouteNames.ambassadorHome
            : RouteNames.fieldAgentHome,
      );
      return;
    }

    switch (state) {
      case EvaluationComplete(:final session):
        if (session.terminationType == 'consent_declined') {
          context.goNamed(RouteNames.beneficiaryIntro);
          return;
        }
        context.goNamed(RouteNames.beneficiaryHome);
        return;
      case EvaluationActive():
        context.goNamed(RouteNames.beneficiaryHome);
        return;
      default:
        context.goNamed(RouteNames.beneficiaryIntro);
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialisation au prochain frame pour éviter les mutations d'état pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(evaluationNotifierProvider);
      if (current is EvaluationIdle) {
        ref.read(evaluationNotifierProvider.notifier).initialize(
              subjectId: widget.subjectId,
              newSubject: widget.newSubject,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evaluationNotifierProvider);

    // Redirection automatique en fin d'évaluation
    ref.listen<EvaluationState>(evaluationNotifierProvider, (_, next) {
      if (next is EvaluationComplete && mounted) {
        final termType = next.session.terminationType;
        if (termType != null && termType.startsWith('urgent_')) {
          return;
        }
        if (termType == 'already_completed') {
          return;
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && context.mounted) {
            if (widget.subjectId != null) {
              context.goNamed(RouteNames.fieldAgentHome);
            } else {
              context.goNamed(RouteNames.beneficiaryHome);
            }
          }
        });
      }
    });

    // Sur tablette : contenu centré avec largeur max
    final rp = context.rp;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: _buildAppBar(context, state),
      body: rp.isTablet
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rp.maxContentW),
                child: _buildBody(state),
              ),
            )
          : _buildBody(state),
    );
  }

  Widget _buildBody(EvaluationState state) => switch (state) {
        EvaluationLoading() => const _LoadingView(),
        EvaluationIdle() => const _LoadingView(),
        EvaluationError(:final message) => _ErrorView(message: message),
        EvaluationActive() => _ActiveView(active: state),
        EvaluationComplete() => _CompleteView(complete: state),
      };

  PreferredSizeWidget _buildAppBar(BuildContext context, EvaluationState state) {
    final progress = switch (state) {
      EvaluationActive(:final progress) => progress,
      EvaluationComplete() => 1.0,
      _ => 0.0,
    };

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 4),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, state),
        ),
        title: Text(switch (state) {
          EvaluationActive(:final blocLabel) when blocLabel != null => blocLabel,
          EvaluationComplete(:final blocLabel) when blocLabel != null => blocLabel,
          _ => 'Évaluation',
        }),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: EvaluationProgressBar(progress: progress),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vues selon l'état
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.brand),
          SizedBox(height: 16),
          Text('Préparation de l\'évaluation...'),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.read(evaluationNotifierProvider.notifier).initialize(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveView extends ConsumerWidget {
  final EvaluationActive active;
  const _ActiveView({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(evaluationNotifierProvider.notifier);

    return Column(
      children: [
        // Liste des messages
        Expanded(
          child: ChatMessageList(
            messages: active.messages,
            onEditStep: notifier.editStep,
          ),
        ),

        // Barre de saisie contextuelle
        ChatInputBar(
          question: active.currentQuestion,
          disabled: active.isSubmitting || active.isTyping,
          onAnswer: (value, {file}) =>
              notifier.answer(value, file: file),
        ),
      ],
    );
  }
}

class _CompleteView extends ConsumerStatefulWidget {
  final EvaluationComplete complete;
  const _CompleteView({required this.complete});

  @override
  ConsumerState<_CompleteView> createState() => _CompleteViewState();
}


/// Sélectionne jusqu'à 3 suggestions pertinentes selon l'intention du thème terminé.
List<ThematicBlocDto> _pickSuggestions(
    List<ThematicBlocDto> blocs, EvaluationComplete complete) {
  // Intentions prioritaires selon ce qui vient d'être fait
  final preferred = switch (complete.blocIntention) {
    ThematicIntention.assessment || ThematicIntention.screening => [
        ThematicIntention.education,
        ThematicIntention.monitoring,
        ThematicIntention.followUp,
      ],
    ThematicIntention.education => [
        ThematicIntention.assessment,
        ThematicIntention.screening,
        ThematicIntention.sharedDecision,
      ],
    ThematicIntention.monitoring || ThematicIntention.followUp => [
        ThematicIntention.education,
        ThematicIntention.preparation,
      ],
    ThematicIntention.preparation => [
        ThematicIntention.assessment,
        ThematicIntention.screening,
      ],
    _ when complete.session.terminationType == 'urgent_referral' => [
        ThematicIntention.education,
        ThematicIntention.monitoring,
      ],
    _ => [
        ThematicIntention.education,
        ThematicIntention.screening,
        ThematicIntention.monitoring,
      ],
  };

  // Exclure le thème qu'on vient de terminer
  final pool = blocs.where((b) => b.key != complete.blocKey).toList();

  final prioritized = pool
      .where((b) => preferred.contains(b.intention))
      .toList()
    ..sort((a, b) => b.priority.compareTo(a.priority));

  if (prioritized.length >= 3) return prioritized.take(3).toList();

  final others = List<ThematicBlocDto>.from(
      pool.where((b) => !preferred.contains(b.intention)))
    ..shuffle(Random());

  return [...prioritized, ...others].take(3).toList();
}

class _CompleteViewState extends ConsumerState<_CompleteView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  List<ThematicBlocDto>? _pickedBlocs;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    ref.read(thematicBlocsProvider.future).then((blocs) {
      if (mounted && _pickedBlocs == null && blocs.isNotEmpty) {
        setState(() => _pickedBlocs = _pickSuggestions(blocs, widget.complete));
      }
    }).ignore();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _CompletionPresentation.fromSession(widget.complete.session);

    return Column(
      children: [
        Expanded(
          child: ChatMessageList(messages: widget.complete.messages),
        ),
        FadeTransition(
          opacity: _fade,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: presentation.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      presentation.icon,
                      size: 44,
                      color: presentation.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  presentation.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.complete.completionMessage ??
                      presentation.fallbackMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  presentation.redirectLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                if (!presentation.showActions &&
                    widget.complete.session.terminationType !=
                        'consent_declined' &&
                    _pickedBlocs != null &&
                    _pickedBlocs!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Explorer un autre sujet',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (_pickedBlocs ?? []).map((bloc) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Icon(bloc.iconData,
                                size: 16, color: AppColors.brand),
                            label: Text(bloc.title),
                            onPressed: () => ref
                                .read(evaluationNotifierProvider.notifier)
                                .startThematic(bloc.key),
                            backgroundColor: AppColors.brandSoft,
                            labelStyle: const TextStyle(
                              color: AppColors.brandStrong,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (presentation.showActions) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.pushNamed(RouteNames.beneficiaryDepistage),
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: const Text('Trouver un site de dépistage'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.pushNamed(RouteNames.beneficiaryConseiller),
                      icon: const Icon(Icons.support_agent_outlined, size: 18),
                      label: const Text('Parler à un conseiller'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.goNamed(
                      widget.complete.session.status == 'cancelled' &&
                              widget.complete.session.terminationType == null
                          ? RouteNames.beneficiaryIntro
                          : RouteNames.beneficiaryHome,
                    ),
                    child: const Text("Retour à l'accueil"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionPresentation {
  final IconData icon;
  final Color accent;
  final String title;
  final String fallbackMessage;
  final String redirectLabel;
  final bool showActions;

  const _CompletionPresentation({
    required this.icon,
    required this.accent,
    required this.title,
    required this.fallbackMessage,
    required this.redirectLabel,
    this.showActions = false,
  });

  factory _CompletionPresentation.fromSession(EvaluationSession session) {
    final type = session.terminationType;

    if (type != null && type.startsWith('urgent_')) {
      return const _CompletionPresentation(
        icon: Icons.warning_amber_rounded,
        accent: AppColors.accent,
        title: 'Orientation urgente',
        fallbackMessage:
            'Des signes d\'alerte ont été détectés. Une évaluation médicale rapide est recommandée.',
        redirectLabel: 'Choisissez une action pour poursuivre votre prise en charge.',
        showActions: true,
      );
    }

    return switch (type) {
      'consent_declined' => const _CompletionPresentation(
          icon: Icons.info_outline_rounded,
          accent: AppColors.brand,
          title: 'Évaluation arrêtée',
          fallbackMessage:
              'Vous avez choisi de ne pas poursuivre l\'évaluation.',
          redirectLabel: 'Redirection en cours...',
        ),
      'already_completed' => const _CompletionPresentation(
          icon: Icons.check_circle_rounded,
          accent: AppColors.support,
          title: 'Évaluation terminée',
          fallbackMessage: 'Explorez un nouveau sujet ci-dessous.',
          redirectLabel: '',
        ),
      _ => const _CompletionPresentation(
          icon: Icons.check_circle_rounded,
          accent: AppColors.support,
          title: 'Évaluation terminée',
          fallbackMessage: 'Votre évaluation est terminée. Merci !',
          redirectLabel: 'Redirection en cours...',
        ),
    };
  }
}
