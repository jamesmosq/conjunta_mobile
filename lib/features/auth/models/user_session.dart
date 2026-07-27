class UserSession {
  const UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        token: json['token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String token;
  final AuthUser user;
}

class ApartmentSummary {
  const ApartmentSummary({required this.id, required this.number, this.tower});

  factory ApartmentSummary.fromJson(Map<String, dynamic> json) => ApartmentSummary(
        id: json['id'] as int,
        number: json['number'] as String? ?? '',
        tower: json['tower'] as String?,
      );

  final int id;
  final String number;
  final String? tower;

  String get label => tower != null && tower!.isNotEmpty ? '$tower - $number' : number;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.tenantId,
    this.apartmentId,
    this.apartments = const [],
    this.fcmToken,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        tenantId: json['tenant_id'] as int?,
        apartmentId: json['apartment_id'] as int?,
        apartments: (json['apartments'] as List<dynamic>?)
                ?.map((a) => ApartmentSummary.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  final int id;
  final String name;
  final String email;
  final String role;
  final int? tenantId;
  final int? apartmentId;
  final List<ApartmentSummary> apartments;
  final String? fcmToken;

  bool get isCopropietario => role == 'copropietario';
  bool get isContratista => role == 'contratista';
  bool get isAdministrador => role == 'administrador';
  bool get isPortero => role == 'portero';

  /// Roles de personal administrativo sin apartamento asignado — tienen
  /// carné de acceso propio (ver StaffBadgeService::ELIGIBLE_ROLES en backend).
  static const _staffBadgeRoles = {
    'administrador',
    'auxiliar_contable',
    'consejo',
    'revisor_fiscal',
  };

  bool get hasStaffBadge => _staffBadgeRoles.contains(role);
}
