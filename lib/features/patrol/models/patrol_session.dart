import 'patrol_route.dart';

class PatrolIncident {
  const PatrolIncident({
    required this.id,
    required this.description,
    required this.severity,
    required this.reportedAt,
    this.photoUrl,
    this.checkpointId,
    this.resolvedAt,
  });

  final int id;
  final String description;
  final String severity;
  final String reportedAt;
  final String? photoUrl;
  final int? checkpointId;
  final String? resolvedAt;

  factory PatrolIncident.fromJson(Map<String, dynamic> json) {
    return PatrolIncident(
      id: json['id'] as int,
      description: json['description'] as String,
      severity: json['severity'] as String,
      reportedAt: json['reported_at'] as String,
      photoUrl: json['photo_url'] as String?,
      checkpointId: json['checkpoint_id'] as int?,
      resolvedAt: json['resolved_at'] as String?,
    );
  }
}

class PatrolSession {
  const PatrolSession({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.checkpointsScanned,
    required this.scannedCheckpointIds,
    this.route,
    this.finishedAt,
    this.compliancePct,
    this.notes,
    this.incidents = const [],
  });

  final int id;
  final String status;
  final String startedAt;
  final String? finishedAt;
  final double? compliancePct;
  final String? notes;
  final int checkpointsScanned;
  final List<int> scannedCheckpointIds;
  final PatrolRoute? route;
  final List<PatrolIncident> incidents;

  bool get isActive => status == 'active';

  PatrolSession copyWith({
    String? status,
    String? finishedAt,
    double? compliancePct,
    int? checkpointsScanned,
    List<int>? scannedCheckpointIds,
    List<PatrolIncident>? incidents,
  }) {
    return PatrolSession(
      id: id,
      status: status ?? this.status,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      compliancePct: compliancePct ?? this.compliancePct,
      notes: notes,
      checkpointsScanned: checkpointsScanned ?? this.checkpointsScanned,
      scannedCheckpointIds: scannedCheckpointIds ?? this.scannedCheckpointIds,
      route: route,
      incidents: incidents ?? this.incidents,
    );
  }

  factory PatrolSession.fromJson(Map<String, dynamic> json) {
    PatrolRoute? route;
    final routeData = json['route'] as Map<String, dynamic>?;
    if (routeData != null) {
      route = PatrolRoute.fromJson(routeData);
    }

    final incidents = (json['incidents'] as List<dynamic>? ?? [])
        .map((e) => PatrolIncident.fromJson(e as Map<String, dynamic>))
        .toList();

    final scannedIds = (json['scanned_checkpoint_ids'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList();

    return PatrolSession(
      id: json['id'] as int,
      status: json['status'] as String,
      startedAt: json['created_at'] as String? ?? '',
      finishedAt: json['finished_at'] as String?,
      compliancePct: (json['compliance_pct'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      checkpointsScanned: json['checkpoints_scanned'] as int? ?? 0,
      scannedCheckpointIds: scannedIds,
      route: route,
      incidents: incidents,
    );
  }
}
