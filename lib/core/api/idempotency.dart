import 'dart:math';

/// Génère un UUID v4, sans dépendance externe.
///
/// Sert de clé d'idempotence : l'API accepte n'importe quelle chaîne, mais un
/// UUID garantit qu'aucune collision ne fera renvoyer à un appareil la réponse
/// mise en cache pour un autre.
String generateIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122

  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
