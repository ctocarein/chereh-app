import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Barre de progression de l'évaluation.
/// [progress] entre 0.0 et 1.0.
class EvaluationProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? color;

  const EvaluationProgressBar({
    super.key,
    required this.progress,
    this.height = 4,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Progression de l\'évaluation',
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          backgroundColor: AppColors.disabled,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.brand,
          ),
        ),
      ),
    );
  }
}
