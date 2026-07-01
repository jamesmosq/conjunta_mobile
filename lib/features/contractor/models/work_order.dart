class WorkOrderMaintenanceInfo {
  const WorkOrderMaintenanceInfo({
    required this.type,
    required this.urgency,
    this.location,
    required this.description,
    this.apartmentNumber,
    this.tower,
  });

  factory WorkOrderMaintenanceInfo.fromJson(Map<String, dynamic> json) =>
      WorkOrderMaintenanceInfo(
        type: json['type'] as String? ?? '',
        urgency: json['urgency'] as String? ?? 'normal',
        location: json['location'] as String?,
        description: json['description'] as String? ?? '',
        apartmentNumber: json['apartment_number'] as String?,
        tower: json['tower'] as String?,
      );

  final String type;
  final String urgency;
  final String? location;
  final String description;
  final String? apartmentNumber;
  final String? tower;

  String get typeLabel => switch (type) {
        'plomeria' => 'Plomería',
        'electricidad' => 'Electricidad',
        'estructura' => 'Estructura',
        'gas' => 'Gas',
        'aseo' => 'Aseo',
        _ => 'Otro',
      };
}

class WorkOrderMaterial {
  const WorkOrderMaterial({
    this.id,
    required this.description,
    required this.quantity,
    required this.unit,
    this.unitCost,
    this.totalCost,
  });

  factory WorkOrderMaterial.fromJson(Map<String, dynamic> json) =>
      WorkOrderMaterial(
        id: json['id'] as int?,
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: json['unit'] as String? ?? 'un',
        unitCost: (json['unit_cost'] as num?)?.toDouble(),
        totalCost: (json['total_cost'] as num?)?.toDouble(),
      );

  final int? id;
  final String description;
  final double quantity;
  final String unit;
  final double? unitCost;
  final double? totalCost;
}

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.estimatedArrivalAt,
    this.maintenanceRequest,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: json['id'] as int,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] as String? ?? '',
        acceptedAt: json['accepted_at'] as String?,
        estimatedArrivalAt: json['estimated_arrival_at'] as String?,
        maintenanceRequest: json['maintenance_request'] != null
            ? WorkOrderMaintenanceInfo.fromJson(
                json['maintenance_request'] as Map<String, dynamic>)
            : null,
      );

  final int id;
  final String status;
  final String createdAt;
  final String? acceptedAt;
  final String? estimatedArrivalAt;
  final WorkOrderMaintenanceInfo? maintenanceRequest;

  bool get isActive =>
      status == 'pending' || status == 'on_the_way' || status == 'in_progress';

  String get statusLabel => switch (status) {
        'pending' => 'Pendiente',
        'on_the_way' => 'En camino',
        'in_progress' => 'En progreso',
        'resolved' => 'Resuelto',
        'approved' => 'Aprobado',
        'rejected' => 'Rechazado',
        _ => status,
      };
}
