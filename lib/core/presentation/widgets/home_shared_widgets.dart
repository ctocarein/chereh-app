import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/screens/pin_screen.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../theme/app_theme.dart';

// ============================================================================
// Avatar circle with user initial
// ============================================================================

class HomeAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const HomeAvatar({super.key, required this.initial, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

// ============================================================================
// Floating icon button with shadow
// ============================================================================

class HomeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const HomeIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.foreground),
        ),
      ),
    );
  }
}

// ============================================================================
// Notification bell with badge
// ============================================================================

class HomeNotificationButton extends StatelessWidget {
  final int badge;
  final VoidCallback? onTap;

  const HomeNotificationButton({super.key, this.badge = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        HomeIconButton(
          icon: Icons.notifications_outlined,
          onTap: onTap ?? () {},
          tooltip: 'Notifications',
        ),
        if (badge > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge > 9 ? '9+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Section header (title + optional "voir tout")
// ============================================================================

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Action tile (icon + title + subtitle + optional badge + chevron)
// ============================================================================

class HomeActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeFg;
  final Color? badgeBg;
  final VoidCallback onTap;

  const HomeActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeFg,
    this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg ?? const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: badgeFg ?? const Color(0xFFE65100),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.disabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom navigation item
// ============================================================================

class HomeNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const HomeNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  color: active ? AppColors.brand : AppColors.disabled,
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? AppColors.brand : AppColors.disabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom nav bar container (shared shell)
// ============================================================================

class HomeBottomNavBar extends StatelessWidget {
  final List<HomeNavItem> items;

  const HomeBottomNavBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: items),
        ),
      ),
    );
  }
}

// ============================================================================
// Security gate PIN banner
// ============================================================================

class SecurityGateBanner extends ConsumerWidget {
  final AuthUser user;
  const SecurityGateBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protégez vos données',
                  style:
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                ),
                Text(
                  'Créez un code PIN pour sécuriser votre profil.',
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                          ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pushPinCreation(context, user),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Créer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Ouvre la création du PIN.
///
/// Poussée hors du router : celui-ci renvoie vers l'accueil tout utilisateur
/// authentifié qui atteint /pin. Une fois le PIN créé, l'état d'auth exige sa
/// vérification et le router prend le relais.
void _pushPinCreation(BuildContext context, AuthUser user) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PinScreen(sessionToken: user.token, hasPin: false),
    ),
  );
}

/// Un compte sans PIN : il reste à en créer un pour protéger ses données.
bool _pinMissing(AuthUser user) => user.gateRequired && !user.secretSet;

String _roleLabel(UserRole role) => switch (role) {
      UserRole.beneficiary => 'Bénéficiaire',
      UserRole.fieldAgent => 'Agent de terrain',
      UserRole.ambassador => 'Ambassadrice',
    };

// ============================================================================
// Profile tab (shared between beneficiary and ambassador)
// ============================================================================

class SharedProfileTab extends ConsumerWidget {
  /// Extra tiles to insert before the logout (e.g. ambassador-specific).
  final List<Widget> extraTiles;

  const SharedProfileTab({super.key, this.extraTiles = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.valueOrNull is AuthStateAuthenticated
        ? (authAsync.valueOrNull as AuthStateAuthenticated).user
        : null;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                children: [
                  HomeAvatar(
                    initial: user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(user.role),
                        style: const TextStyle(
                          color: AppColors.brandStrong,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: 'Informations personnelles',
                    onTap: user == null
                        ? null
                        : () => _showPersonalInfo(context, user),
                  ),
                  // Ses propres données de santé : sans objet pour qui évalue
                  // les autres.
                  if (user?.role == UserRole.beneficiary)
                    const _ProfileTile(
                      icon: Icons.medical_information_outlined,
                      label: 'Informations médicales',
                      comingSoon: true,
                    ),
                  _ProfileTile(
                    icon: Icons.lock_outline,
                    label: 'Sécurité & PIN',
                    trailing: user == null
                        ? null
                        : _StatusChip(
                            label: _pinMissing(user) ? 'À créer' : 'Activé',
                            color: _pinMissing(user)
                                ? AppColors.accent
                                : const Color(0xFF2E7D53),
                            background: _pinMissing(user)
                                ? AppColors.accentSoft
                                : const Color(0xFFDDF3E7),
                          ),
                    onTap: user == null
                        ? null
                        : () => _pinMissing(user)
                            ? _pushPinCreation(context, user)
                            : ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Votre compte est protégé par un code PIN.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              ),
                  ),
                  const _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    comingSoon: true,
                  ),
                  const _ProfileTile(
                    icon: Icons.help_outline,
                    label: 'Aide & Support',
                    comingSoon: true,
                  ),
                  ...extraTiles,
                  const SizedBox(height: 16),
                  _ProfileTile(
                    icon: Icons.logout_outlined,
                    label: 'Déconnexion',
                    labelColor: AppColors.accent,
                    iconColor: AppColors.accent,
                    onTap: () =>
                        ref.read(authNotifierProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Nom, téléphone et rôle, en lecture : ce que l'application sait de la
/// personne connectée.
void _showPersonalInfo(BuildContext context, AuthUser user) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      Widget row(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? '—' : value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.disabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Informations personnelles',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              row('Nom', user.name),
              row('Téléphone', user.phone),
              row('Rôle', _roleLabel(user.role)),
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Pas encore disponible : la ligne l'annonce et ne promet pas d'action.
  final bool comingSoon;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.labelColor,
    this.iconColor,
    this.trailing,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(
            icon,
            color: comingSoon
                ? AppColors.disabled
                : (iconColor ?? AppColors.muted),
            size: 22,
          ),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: comingSoon
                      ? AppColors.muted
                      : (labelColor ?? AppColors.foreground),
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: comingSoon
              ? const _StatusChip(
                  label: 'Bientôt',
                  color: AppColors.muted,
                  background: AppColors.surfaceAlt,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ?trailing,
                    const Icon(Icons.chevron_right,
                        color: AppColors.disabled, size: 20),
                  ],
                ),
          onTap: comingSoon ? null : onTap,
        ),
        const Divider(height: 1, color: Color(0xFFF0F2F4)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================================
// Placeholder tab (bientôt disponible)
// ============================================================================

class PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PlaceholderTab({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.brand, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted),
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
