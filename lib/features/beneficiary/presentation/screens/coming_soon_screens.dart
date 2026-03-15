import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================================
// Dépistage de Proximité — bientôt disponible
// ============================================================================

class DepistageProximiteScreen extends StatelessWidget {
  const DepistageProximiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoonScreen(
      title: 'Dépistage de Proximité',
      subtitle: 'Trouvez un site de dépistage près de chez vous',
      icon: Icons.location_on_rounded,
      color: AppColors.accent,
      colorSoft: AppColors.accentSoft,
      features: const [
        _Feature(
          icon: Icons.map_outlined,
          label: 'Carte interactive',
          detail: 'Visualisez les sites de dépistage autour de vous',
        ),
        _Feature(
          icon: Icons.filter_list_rounded,
          label: 'Filtres avancés',
          detail: 'Par type d\'examen, distance et disponibilité',
        ),
        _Feature(
          icon: Icons.access_time_rounded,
          label: 'Horaires en temps réel',
          detail: 'Jours d\'ouverture, contacts et accès',
        ),
        _Feature(
          icon: Icons.calendar_month_outlined,
          label: 'Prise de rendez-vous',
          detail: 'Réservez directement depuis l\'application',
        ),
      ],
    );
  }
}

// ============================================================================
// Parler À Un Conseiller — bientôt disponible
// ============================================================================

class ConseillerScreen extends StatelessWidget {
  const ConseillerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoonScreen(
      title: 'Parler À Un Conseiller',
      subtitle: 'Un professionnel de santé à votre écoute',
      icon: Icons.support_agent_rounded,
      color: AppColors.support,
      colorSoft: const Color(0xFFD5F5E5),
      isPremium: true,
      features: const [
        _Feature(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat sécurisé',
          detail: 'Échangez avec un conseiller médical qualifié',
        ),
        _Feature(
          icon: Icons.videocam_outlined,
          label: 'Consultation vidéo',
          detail: 'Rendez-vous en visio sur créneaux disponibles',
        ),
        _Feature(
          icon: Icons.person_pin_outlined,
          label: 'Suivi personnalisé',
          detail: 'Un professionnel dédié à votre parcours de santé',
        ),
        _Feature(
          icon: Icons.schedule_rounded,
          label: 'Disponible 7j/7',
          detail: 'Accès prioritaire pour les membres Premium',
        ),
      ],
    );
  }
}

// ============================================================================
// Widget partagé
// ============================================================================

class _Feature {
  final IconData icon;
  final String label;
  final String detail;
  const _Feature({required this.icon, required this.label, required this.detail});
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color colorSoft;
  final bool isPremium;
  final List<_Feature> features;

  const _ComingSoonScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.colorSoft,
    this.isPremium = false,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero SliverAppBar ───────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(
                title: title,
                subtitle: subtitle,
                icon: icon,
                color: color,
                isPremium: isPremium,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // ── Corps ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Badge bientôt disponible
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: colorSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          'Bientôt disponible',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre section
                Text(
                  'Ce qui vous attend',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                ),
                const SizedBox(height: 12),

                // Liste des fonctionnalités
                ...features.map(
                  (f) => _FeatureTile(
                    feature: f,
                    color: color,
                    colorSoft: colorSoft,
                  ),
                ),

                const SizedBox(height: 28),

                // CTA notification
                _NotifyButton(color: color),

                if (isPremium) ...[
                  const SizedBox(height: 16),
                  _PremiumNote(color: color, colorSoft: colorSoft),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPremium;

  const _HeroSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.70)],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -30,
            right: -30,
            child: _DecorCircle(size: 140, opacity: 0.08),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: _DecorCircle(size: 100, opacity: 0.06),
          ),
          // Contenu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Feature tile ─────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final Color color;
  final Color colorSoft;

  const _FeatureTile({
    required this.feature,
    required this.color,
    required this.colorSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.detail,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 16, color: AppColors.disabled),
        ],
      ),
    );
  }
}

// ── CTA notification ─────────────────────────────────────────────────────────

class _NotifyButton extends StatelessWidget {
  final Color color;
  const _NotifyButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vous serez notifié lors du lancement !'),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        icon: const Icon(Icons.notifications_outlined, size: 18),
        label: const Text('M\'avertir lors du lancement'),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

// ── Note Premium ─────────────────────────────────────────────────────────────

class _PremiumNote extends StatelessWidget {
  final Color color;
  final Color colorSoft;
  const _PremiumNote({required this.color, required this.colorSoft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cette fonctionnalité sera réservée aux membres Premium au lancement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
