import 'package:flutter/material.dart';

/// Données d'une page d'onboarding.
class OnboardingData {
  final Widget illustration;
  final String title;
  final String description;

  const OnboardingData({
    required this.illustration,
    required this.title,
    required this.description,
  });
}

/// Page individuelle de l'onboarding.
/// S'affiche sur fond brand (géré par le Scaffold parent).
class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Titre — grand, blanc, gras, aligné à gauche (comme la ref)
          Text(
            data.title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),

          // Illustration — prend tout l'espace disponible, centrée
          Expanded(
            child: Center(child: data.illustration),
          ),

          // Description — blanc, lisible, compact
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.55,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
