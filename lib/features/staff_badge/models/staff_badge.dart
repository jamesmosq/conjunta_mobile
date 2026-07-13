class StaffBadge {
  const StaffBadge({
    required this.code,
    required this.userId,
    required this.userName,
    required this.role,
    required this.isInside,
  });

  factory StaffBadge.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return StaffBadge(
      code: json['code'] as String? ?? '',
      userId: user['id'] as int? ?? 0,
      userName: user['name'] as String? ?? '',
      role: user['role'] as String?,
      isInside: json['is_inside'] as bool? ?? false,
    );
  }

  final String code;
  final int userId;
  final String userName;
  final String? role;
  final bool isInside;

  static const _roleLabels = {
    'administrador': 'Administrador',
    'auxiliar_contable': 'Auxiliar contable',
    'consejo': 'Consejo',
    'revisor_fiscal': 'Revisor fiscal',
  };

  String get roleLabel => _roleLabels[role] ?? role ?? '';
}
