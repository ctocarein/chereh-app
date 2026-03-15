import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/responsive/app_responsive.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_illustration_1.dart';
import '../widgets/onboarding_illustration_2.dart';
import '../widgets/onboarding_illustration_3.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/onboarding_preference.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  static const _pages = [
    OnboardingData(
      illustration: OnboardingIllustration1(),
      title: 'Bienvenue sur Chereh',
      description:
          'Une plateforme pensée pour faciliter l\'accès aux soins '
          'et au soutien communautaire, peu importe où vous vous trouvez.',
    ),
    OnboardingData(
      illustration: OnboardingIllustration2(),
      title: 'Évaluation simplifiée',
      description:
          'Répondez à quelques questions pour que nos agents vous orientent '
          'vers les ressources adaptées à votre situation.',
    ),
    OnboardingData(
      illustration: OnboardingIllustration3(),
      title: 'Connectez votre communauté',
      description:
          'En tant qu\'ambassadeur ou agent de terrain, aidez votre entourage '
          'à accéder aux services essentiels et suivez leur parcours.',
    ),
  ];

  bool get _isLast => _current == _pages.length - 1;

  void _next() {
    if (_isLast) {
      _continue();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _continue() async {
    await OnboardingPreference.markSeen();
    if (mounted) context.goNamed(RouteNames.privacy);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.rp;
    // Les cercles décoratifs s'adaptent à la largeur d'écran
    final c1 = rp.screenW * 0.85;
    final c2 = rp.screenW * 0.65;
    final c3 = rp.screenW * 0.40;
    final btnSz = rp.isTablet ? 60.0 : 52.0;
    final navPad = rp.hPad;

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Stack(
        children: [
          _BgCircle(size: c1, top: -c1 * 0.33, right: -c1 * 0.27),
          _BgCircle(size: c2, bottom: -c2 * 0.38, left: -c2 * 0.27),
          _BgCircle(size: c3, top: rp.screenH * 0.38, left: -c3 * 0.34),

          SafeArea(
            child: Column(
              children: [
                // Barre du haut
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: rp.hPad, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _continue,
                        child: Text(
                          'Passer',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => OnboardingPage(data: _pages[i]),
                  ),
                ),

                // Navigation bas
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: navPad),
                  child: Row(
                    children: [
                      if (_current > 0)
                        _NavButton(
                          size: btnSz,
                          onTap: _back,
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: rp.iconSz),
                        )
                      else
                        SizedBox(width: btnSz),

                      Expanded(
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _controller,
                            count: _pages.length,
                            effect: ExpandingDotsEffect(
                              activeDotColor: Colors.white,
                              dotColor:
                                  Colors.white.withValues(alpha: 0.35),
                              dotHeight: 8,
                              dotWidth: 8,
                              expansionFactor: 3,
                            ),
                          ),
                        ),
                      ),

                      _NavButton(
                        size: btnSz,
                        onTap: _next,
                        dark: true,
                        child: Icon(
                          _isLast ? Icons.check : Icons.arrow_forward,
                          color: Colors.white,
                          size: rp.iconSz,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: rp.spL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets locaux
// ---------------------------------------------------------------------------

class _BgCircle extends StatelessWidget {
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _BgCircle({
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
    );
  }
}

/// Bouton circulaire de navigation (style référence).
class _NavButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool dark;
  final double size;

  const _NavButton({
    required this.onTap,
    required this.child,
    this.dark = false,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF1A1A2E)
              : Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
