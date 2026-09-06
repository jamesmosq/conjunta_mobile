class ShiftIncident {
  const ShiftIncident({
    required this.id,
    required this.description,
    required this.category,
    required this.urgency,
    required this.createdAt,
    this.reportedBy,
    this.adminNotified = false,
  });

  final int id;
  final String description;
  final String category;
  final String urgency;
  final String createdAt;
  final String? reportedBy;
  final bool adminNotified;

  bool get isUrgent => urgency == 'urgent';

  String get categoryLabel => switch (category) {
        'security' => 'Seguridad',
        'damage' => 'Daño',
        'noise' => 'Ruido',
        'delivery' => 'Entrega',
        _ => 'Otro',
      };

  factory ShiftIncident.fromJson(Map<String, dynamic> json) => ShiftIncident(
        id: json['id'] as int,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        urgency: json['urgency'] as String? ?? 'normal',
        createdAt: json['created_at']?.toString() ?? '',
        reportedBy: json['reported_by'] as String?,
        adminNotified: json['admin_notified'] as bool? ?? false,
      );
}
