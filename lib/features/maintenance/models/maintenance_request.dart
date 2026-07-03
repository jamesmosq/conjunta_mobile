class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.type,
    required this.urgency,
    this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    this.apartmentId,
    this.photoUrls = const [],
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: json['id'] as int,
        type: json['type'] as String? ?? 'otro',
        urgency: json['urgency'] as String? ?? 'normal',
        location: json['location'] as String?,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] as String? ?? '',
        apartmentId: json['apartment_id'] as int?,
        photoUrls: (json['photo_urls'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  final int id;
  final String type;
  final String urgency;
  final String? location;
  final String description;
  final String status;
  final String createdAt;
  final int? apartmentId;
  final List<String> photoUrls;

  String get urgencyLabel => urgency == 'urgent' ? 'Urgente' : 'Normal';

  String get typeLabel => switch (type) {
        'corrective' => 'Correctivo',
        'preventive' => 'Preventivo',
        'improvement' => 'Mejora',
        _ => 'Correctivo',
      };
}

class TimelineEntry {
  const TimelineEntry({
    required this.event,
    this.fromStatus,
    this.toStatus,
    required this.occurredAt,
    this.note,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
        event: json['event'] as String? ?? '',
        fromStatus: json['from_status'] as String?,
        toStatus: json['to_status'] as String?,
        occurredAt: json['occurred_at'] as String? ?? '',
        note: json['note'] as String?,
      );

  final String event;
  final String? fromStatus;
  final String? toStatus;
  final String occurredAt;
  final String? note;
}
