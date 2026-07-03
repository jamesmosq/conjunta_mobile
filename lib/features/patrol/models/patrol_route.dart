import 'patrol_checkpoint.dart';

class PatrolRoute {
  const PatrolRoute({
    required this.id,
    required this.name,
    required this.checkpoints,
    this.description,
    this.estimatedMinutes,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? description;
  final int? estimatedMinutes;
  final bool isActive;
  final List<PatrolCheckpoint> checkpoints;

  factory PatrolRoute.fromJson(Map<String, dynamic> json) {
    final cps = (json['checkpoints'] as List<dynamic>? ?? [])
        .map((e) => PatrolCheckpoint.fromJson(e as Map<String, dynamic>))
        .toList();
    cps.sort((a, b) => a.sequence.compareTo(b.sequence));
    return PatrolRoute(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      estimatedMinutes: json['estimated_minutes'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      checkpoints: cps,
    );
  }
}
