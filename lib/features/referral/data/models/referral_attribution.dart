/// Résultat d'une attribution réussie : l'ambassadrice qui a parrainé l'utilisateur.
class ReferralAttribution {
  final String? ambassadorId;
  final String? ambassadorName;
  final String? referralCode;

  const ReferralAttribution({
    required this.ambassadorId,
    required this.ambassadorName,
    required this.referralCode,
  });

  factory ReferralAttribution.fromJson(Map<String, dynamic> json) {
    final ambassador = json['ambassador'] as Map<String, dynamic>?;
    return ReferralAttribution(
      ambassadorId:   ambassador?['id'] as String?,
      ambassadorName: ambassador?['name'] as String?,
      referralCode:   json['referral_code'] as String?,
    );
  }

  /// Persiste dans SharedPreferences.
  Map<String, String> toPrefsMap() => {
    'referral_ambassador_id':   ambassadorId   ?? '',
    'referral_ambassador_name': ambassadorName ?? '',
    'referral_code':            referralCode   ?? '',
  };

  static ReferralAttribution? fromPrefsMap(Map<String, String?> map) {
    final id   = map['referral_ambassador_id'];
    final name = map['referral_ambassador_name'];
    final code = map['referral_code'];
    if (id == null || id.isEmpty) return null;
    return ReferralAttribution(
      ambassadorId:   id,
      ambassadorName: name?.isNotEmpty == true ? name : null,
      referralCode:   code?.isNotEmpty == true ? code : null,
    );
  }
}
