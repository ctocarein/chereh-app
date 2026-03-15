enum UserRole { beneficiary, fieldAgent, ambassador }

class AuthUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String token;
  /// true → données sensibles masquées jusqu'à unlock ou création PIN
  final bool gateRequired;
  /// true → un PIN existe (unlock requis) / false → aucun PIN (création proposée)
  final bool secretSet;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.token,
    this.gateRequired = false,
    this.secretSet = false,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? role,
    String? token,
    bool? gateRequired,
    bool? secretSet,
  }) =>
      AuthUser(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        token: token ?? this.token,
        gateRequired: gateRequired ?? this.gateRequired,
        secretSet: secretSet ?? this.secretSet,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.phone == phone &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, phone, role);
}

sealed class AuthState {
  const AuthState();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Compte existant — PIN requis.
/// [hasPin] false → créer un PIN  /  true → saisir le PIN existant
class AuthStatePinRequired extends AuthState {
  final String sessionToken;
  final bool hasPin;
  const AuthStatePinRequired({required this.sessionToken, required this.hasPin});
}

class AuthStateAuthenticated extends AuthState {
  final AuthUser user;
  const AuthStateAuthenticated(this.user);
}
