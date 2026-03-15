import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/referral_attribution_notifier.dart';

/// Bannière affichée sur le home du bénéficiaire quand une attribution est trouvée.
/// "Vous avez été invité(e) par [Nom]"
/// Se masque automatiquement si aucune attribution n'est disponible.
class ReferralWelcomeBanner extends ConsumerWidget {
  const ReferralWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attrAsync = ref.watch(referralAttributionProvider);

    return attrAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (attribution) {
        if (attribution == null) return const SizedBox.shrink();

        final name = attribution.ambassadorName;
        final label = name != null && name.isNotEmpty
            ? 'Vous avez été invité(e) par $name'
            : 'Vous avez rejoint via une invitation';

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue !',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.brandStrong,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.brandStrong,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
