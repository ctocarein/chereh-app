import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/evaluation_notifier.dart';
import '../providers/evaluation_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/evaluation_progress_bar.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  /// UUID du bénéficiaire ciblé — renseigné uniquement en mode évaluation assistée.
  final String? subjectId;

  const EvaluationScreen({super.key, this.subjectId});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialisation au prochain frame pour éviter les mutations d'état pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(evaluationNotifierProvider.notifier)
          .initialize(subjectId: widget.subjectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evaluationNotifierProvider);

    // Redirection automatique en fin d'évaluation
    ref.listen<EvaluationState>(evaluationNotifierProvider, (_, next) {
      if (next is EvaluationComplete && mounted) {
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
          onPressed: () => context.goNamed(RouteNames.beneficiaryIntro),
        ),
        title: const Text('Évaluation'),
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
          Text('Préparation de l\'évaluation…'),
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

class _CompleteView extends StatefulWidget {
  final EvaluationComplete complete;
  const _CompleteView({required this.complete});

  @override
  State<_CompleteView> createState() => _CompleteViewState();
}

class _CompleteViewState extends State<_CompleteView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

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
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.support.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 44,
                      color: AppColors.support,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.complete.completionMessage ??
                      'Votre évaluation est terminée. Merci !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Redirection en cours…',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
