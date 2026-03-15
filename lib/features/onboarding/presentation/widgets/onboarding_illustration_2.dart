import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Page 2 — Évaluation : carte formulaire flottante avec coches animées.
class OnboardingIllustration2 extends StatefulWidget {
  const OnboardingIllustration2({super.key});

  @override
  State<OnboardingIllustration2> createState() =>
      _OnboardingIllustration2State();
}

class _OnboardingIllustration2State extends State<OnboardingIllustration2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Opacité [0,1] d'un élément selon son seuil d'apparition
  double _opacity(double threshold) {
    final t = _ctrl.value;
    if (t < threshold) return 0.0;
    // Disparition fluide vers la fin du cycle
    if (t > 0.88) return (1.0 - (t - 0.88) / 0.12).clamp(0.0, 1.0);
    return ((t - threshold) / 0.08).clamp(0.0, 1.0);
  }

  double get _floatY => sin(_ctrl.value * 2 * pi) * 7;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.person_outline, 'Situation personnelle'),
      (Icons.local_hospital_outlined, 'Accès aux soins'),
      (Icons.track_changes_outlined, 'Suivi recommandé'),
    ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatY),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête carte
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined,
                          color: AppColors.brand, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Évaluation',
                        style: TextStyle(
                          color: AppColors.brandStrong,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      // Barre de progression animée
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 60,
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _ctrl.value.clamp(0.0, 0.88),
                            backgroundColor:
                                AppColors.brand.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.brand),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Items
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _CheckRow(
                          icon: items[i].$1,
                          label: items[i].$2,
                          checkOpacity: _opacity(0.15 + i * 0.22),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double checkOpacity;

  const _CheckRow({
    required this.icon,
    required this.label,
    required this.checkOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icône catégorie
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.brand),
        ),
        const SizedBox(width: 12),

        // Lignes de texte placeholder
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 8,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Coche animée
        Opacity(
          opacity: checkOpacity,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.support,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
