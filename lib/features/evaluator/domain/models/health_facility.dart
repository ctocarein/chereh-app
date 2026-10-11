/// Un établissement où orienter une patiente.
///
/// [hasMammography] décide de l'orientation : une femme à risque doit savoir
/// où passer une mammographie, pas seulement où consulter.
class HealthFacility {
  final int id;
  final String name;
  final String? kind;
  final String? municipality;
  final String? healthDistrict;
  final String? address;
  final String? phone;
  final bool hasMammography;

  /// Ligne d'exemple posée en attendant le référentiel réel : l'écran la
  /// signale, elle ne doit pas passer pour vraie.
  final bool isSample;

  const HealthFacility({
    required this.id,
    required this.name,
    this.kind,
    this.municipality,
    this.healthDistrict,
    this.address,
    this.phone,
    this.hasMammography = false,
    this.isSample = false,
  });

  /// « Cocody · District de Cocody-Bingerville », ce qui est connu.
  String? get location {
    final parts = [municipality, healthDistrict]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get kindLabel => switch (kind) {
        'chu' => 'CHU',
        'chr' => 'CHR',
        'hospital' => 'Hôpital',
        'clinic' => 'Clinique',
        'health_center' => 'Centre de santé',
        final String other when other.trim().isNotEmpty => other,
        _ => null,
      };

  factory HealthFacility.fromJson(Map<String, dynamic> json) => HealthFacility(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? 'Établissement sans nom',
        kind: _emptyToNull(json['kind']),
        municipality: _emptyToNull(json['municipality']),
        healthDistrict: _emptyToNull(json['health_district']),
        address: _emptyToNull(json['address']),
        phone: _emptyToNull(json['phone']),
        hasMammography: json['has_mammography'] == true,
        isSample: json['is_sample'] == true,
      );
}

String? _emptyToNull(dynamic raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}
