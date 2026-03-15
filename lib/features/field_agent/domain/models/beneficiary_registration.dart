class BeneficiaryRegistration {
  final String identityId;
  final String phone;
  final bool isNew;

  const BeneficiaryRegistration({
    required this.identityId,
    required this.phone,
    required this.isNew,
  });

  factory BeneficiaryRegistration.fromJson(Map<String, dynamic> json) =>
      BeneficiaryRegistration(
        identityId: json['identity_id'] as String,
        phone: json['phone'] as String,
        isNew: json['is_new'] as bool? ?? false,
      );
}
