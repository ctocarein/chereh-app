import 'package:flutter/material.dart';

enum BannerType { error, success, info, warning }

/// Bannière de statut contextuelle (erreur, succès, info, avertissement).
///
/// ```dart
/// StatusBanner(message: 'Code invalide', type: BannerType.error)
/// StatusBanner(message: 'SMS envoyé !', type: BannerType.success)
/// ```
class StatusBanner extends StatelessWidget {
  final String message;
  final BannerType type;

  const StatusBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (type) {
      BannerType.error => (
          colors.errorContainer,
          colors.onErrorContainer,
          Icons.error_outline,
        ),
      BannerType.success => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          Icons.check_circle_outline,
        ),
      BannerType.info => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          Icons.info_outline,
        ),
      BannerType.warning => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          Icons.warning_amber_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: fg, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
