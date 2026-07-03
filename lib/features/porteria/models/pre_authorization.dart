class PreAuthorization {
  const PreAuthorization({
    required this.id,
    this.apartmentId,
    required this.visitorName,
    this.documentNumber,
    this.photoUrl,
    this.expectedAt,
    required this.arrivalMode,
    this.vehiclePlate,
    this.vehicleType,
    this.isRecurring = false,
    this.allowedDays = const [],
    this.allowedFrom,
    this.allowedUntil,
    this.relationType,
    required this.isActive,
    this.expiresAt,
    this.isValidNow = false,
  });

  factory PreAuthorization.fromJson(Map<String, dynamic> json) =>
      PreAuthorization(
        id: json['id'] as int,
        apartmentId: json['apartment_id'] as int?,
        visitorName: json['visitor_name'] as String? ?? '',
        documentNumber: json['document_number'] as String?,
        photoUrl: json['photo_url'] as String?,
        expectedAt: json['expected_at']?.toString(),
        arrivalMode: json['arrival_mode'] as String? ?? 'walk',
        vehiclePlate: json['vehicle_plate'] as String?,
        vehicleType: json['vehicle_type'] as String?,
        isRecurring: json['is_recurring'] as bool? ?? false,
        allowedDays:
            (json['allowed_days'] as List?)?.map((e) => e as int).toList() ??
                [],
        allowedFrom: json['allowed_from'] as String?,
        allowedUntil: json['allowed_until'] as String?,
        relationType: json['relation_type'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        expiresAt: json['expires_at']?.toString(),
        isValidNow: json['is_valid_now'] as bool? ?? false,
      );

  final int id;
  final int? apartmentId;
  final String visitorName;
  final String? documentNumber;
  final String? photoUrl;
  final String? expectedAt;
  final String arrivalMode;
  final String? vehiclePlate;
  final String? vehicleType;
  final bool isRecurring;
  final List<int> allowedDays;
  final String? allowedFrom;
  final String? allowedUntil;
  final String? relationType;
  final bool isActive;
  final String? expiresAt;
  final bool isValidNow;

  bool get isVehicle => arrivalMode == 'vehicle';

  String get arrivalModeLabel =>
      arrivalMode == 'vehicle' ? 'Vehículo' : 'A pie';

  String get relationTypeLabel => switch (relationType) {
        'domestic' => 'Empleado doméstico',
        'family' => 'Familiar',
        'provider' => 'Proveedor',
        _ => 'Otro',
      };
}
