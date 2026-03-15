import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../router/route_names.dart';
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
            onPressed: () => context.goNamed(
              RouteNames.pin,
              extra: AuthStatePinRequired(
                sessionToken: user.token,
                hasPin: false,
              ),
            ),
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
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.medical_information_outlined,
                    label: 'Informations médicales',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.lock_outline,
                    label: 'Sécurité & PIN',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.help_outline,
                    label: 'Aide & Support',
                    onTap: () {},
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

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon,
              color: iconColor ?? AppColors.muted, size: 22),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: labelColor ?? AppColors.foreground,
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: Icon(Icons.chevron_right,
              color: AppColors.disabled, size: 20),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Color(0xFFF0F2F4)),
      ],
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
