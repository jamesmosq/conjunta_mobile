class ParkingSpot {
  const ParkingSpot({
    required this.id,
    this.apartmentId,
    required this.identifier,
    required this.type,
    required this.isAvailable,
    required this.isEnabled,
    this.notes,
  });

  final int id;
  final int? apartmentId;
  final String identifier;
  final String type;
  final bool isAvailable;
  final bool isEnabled;
  final String? notes;

  String get typeLabel => switch (type) {
        'fixed' => 'Fijo',
        'visitor' => 'Visitantes',
        _ => type,
      };

  factory ParkingSpot.fromJson(Map<String, dynamic> json) => ParkingSpot(
        id: json['id'] as int,
        apartmentId: json['apartment_id'] as int?,
        identifier: json['identifier'] as String? ?? '',
        type: json['type'] as String? ?? 'visitor',
        isAvailable: json['is_available'] as bool? ?? false,
        isEnabled: json['is_enabled'] as bool? ?? true,
        notes: json['notes'] as String?,
      );
}
