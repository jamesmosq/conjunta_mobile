class UserSession {
  const UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        token: json['token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String token;
  final AuthUser user;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.tenantId,
    this.apartmentId,
    this.fcmToken,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        tenantId: json['tenant_id'] as int?,
        apartmentId: json['apartment_id'] as int?,
      );

  final int id;
  final String name;
  final String email;
  final String role;
  final int? tenantId;
  final int? apartmentId;
  final String? fcmToken;

  bool get isCopropietario => role == 'copropietario';
  bool get isContratista => role == 'contratista';
  bool get isAdministrador => role == 'administrador';
  bool get isPortero => role == 'portero';
}
