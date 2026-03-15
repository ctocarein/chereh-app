class AmbassadorMetrics {
  final int totalReferrals;
  final int activeReferrals;
  final int completedUsages;
  final int badgesEarned;
  final String levelCode;

  const AmbassadorMetrics({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.completedUsages,
    required this.badgesEarned,
    required this.levelCode,
  });

  factory AmbassadorMetrics.fromJson(Map<String, dynamic> json) =>
      AmbassadorMetrics(
        totalReferrals: (json['total_referrals'] as num?)?.toInt() ?? 0,
        activeReferrals: (json['active_referrals'] as num?)?.toInt() ?? 0,
        completedUsages: (json['completed_usages'] as num?)?.toInt() ?? 0,
        badgesEarned: (json['badges_earned'] as num?)?.toInt() ?? 0,
        levelCode: json['level_code'] as String? ?? 'starter',
      );

  String get levelLabel => switch (levelCode) {
        'starter' => 'Débutant',
        'bronze' => 'Bronze',
        'silver' => 'Argent',
        'gold' => 'Or',
        'platinum' => 'Platine',
        _ => levelCode,
      };
}

class ReferralModel {
  final String id;
  final String code;
  final String? channel;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime? lastUsedAt;
  final bool isRevoked;
  final bool isExpired;

  const ReferralModel({
    required this.id,
    required this.code,
    this.channel,
    this.expiresAt,
    this.revokedAt,
    this.lastUsedAt,
    required this.isRevoked,
    required this.isExpired,
  });

  bool get isActive => !isRevoked && !isExpired;

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        id: json['id'].toString(),
        code: json['code'] as String,
        channel: json['channel'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        revokedAt: json['revoked_at'] != null
            ? DateTime.tryParse(json['revoked_at'] as String)
            : null,
        lastUsedAt: json['last_used_at'] != null
            ? DateTime.tryParse(json['last_used_at'] as String)
            : null,
        isRevoked: json['is_revoked'] as bool? ?? false,
        isExpired: json['is_expired'] as bool? ?? false,
      );
}

class GeneratedReferral {
  final ReferralModel referral;
  final String url;
  final bool reused;
  final int? remainingWeekly;

  const GeneratedReferral({
    required this.referral,
    required this.url,
    required this.reused,
    this.remainingWeekly,
  });
}
