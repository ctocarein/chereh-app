import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Page 3 — Communauté : réseau de nœuds personnes avec lignes animées.
class OnboardingIllustration3 extends StatefulWidget {
  const OnboardingIllustration3({super.key});

  @override
  State<OnboardingIllustration3> createState() =>
      _OnboardingIllustration3State();
}

class _OnboardingIllustration3State extends State<OnboardingIllustration3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Opacité d'apparition d'un nœud avec stagger
  double _nodeOpacity(double offset) {
    final t = (_ctrl.value + offset) % 1.0;
    if (t > 0.85) return (1.0 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
    return (t / 0.25).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final pulseScale = 1.0 + sin(t * 2 * pi) * 0.06;

        const size = 260.0;
        const cx = size / 2;
        const r = 92.0;

        // Positions cardinales des nœuds satellites
        const positions = [
          Offset(cx, cx - r), // Nord
          Offset(cx + r, cx), // Est
          Offset(cx, cx + r), // Sud
          Offset(cx - r, cx), // Ouest
        ];

        final nodeOps = [
          _nodeOpacity(0.0),
          _nodeOpacity(0.18),
          _nodeOpacity(0.36),
          _nodeOpacity(0.54),
        ];

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Lignes de connexion
              CustomPaint(
                size: const Size(size, size),
                painter: _NetworkPainter(
                  center: const Offset(cx, cx),
                  nodes: positions,
                  nodeOpacities: nodeOps,
                ),
              ),

              // Nœud central (pulsant)
              Positioned(
                left: cx - 34,
                top: cx - 34,
                child: Transform.scale(
                  scale: pulseScale,
                  child: const _PersonNode(size: 68, isCenter: true),
                ),
              ),

              // Nœuds satellites
              for (int i = 0; i < 4; i++)
                Positioned(
                  left: positions[i].dx - 26,
                  top: positions[i].dy - 26,
                  child: Opacity(
                    opacity: nodeOps[i],
                    child: const _PersonNode(size: 52, isCenter: false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PersonNode extends StatelessWidget {
  final double size;
  final bool isCenter;

  const _PersonNode({required this.size, required this.isCenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCenter ? Colors.white : Colors.white.withValues(alpha: 0.88),
        shape: BoxShape.circle,
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.person_outline,
        size: size * 0.5,
        color: isCenter ? AppColors.brand : AppColors.brandStrong,
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodes;
  final List<double> nodeOpacities;

  const _NetworkPainter({
    required this.center,
    required this.nodes,
    required this.nodeOpacities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodes.length; i++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: nodeOpacities[i] * 0.45)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodes[i], paint);
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) =>
      old.nodeOpacities != nodeOpacities;
}
