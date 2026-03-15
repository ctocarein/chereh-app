import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Page 1 — Bienvenue : croix santé centrale + anneaux pulsants + icônes en orbite.
class OnboardingIllustration1 extends StatefulWidget {
  const OnboardingIllustration1({super.key});

  @override
  State<OnboardingIllustration1> createState() =>
      _OnboardingIllustration1State();
}

class _OnboardingIllustration1State extends State<OnboardingIllustration1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _ringOpacity(double offset) {
    final t = (_ctrl.value + offset) % 1.0;
    return (1.0 - t).clamp(0.0, 1.0) * 0.28;
  }

  double _ringScale(double offset) {
    final t = (_ctrl.value + offset) % 1.0;
    return 0.15 + t * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final angle = _ctrl.value * 2 * pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Anneaux pulsants
              for (final offset in [0.0, 0.38, 0.68])
                Transform.scale(
                  scale: _ringScale(offset),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: _ringOpacity(offset)),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Cercle central avec icône santé
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 48,
                  color: AppColors.brand,
                ),
              ),

              // Icônes en orbite
              for (int i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    cos(angle + i * 2 * pi / 3) * 108,
                    sin(angle + i * 2 * pi / 3) * 108,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      const [
                        Icons.favorite_border,
                        Icons.medical_services_outlined,
                        Icons.people_outline,
                      ][i],
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
