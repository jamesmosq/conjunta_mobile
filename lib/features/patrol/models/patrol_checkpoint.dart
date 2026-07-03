class PatrolCheckpoint {
  const PatrolCheckpoint({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sequence,
    this.description,
    this.qrPayload,
  });

  final int id;
  final String uuid;
  final String name;
  final int sequence;
  final String? description;
  final String? qrPayload;

  factory PatrolCheckpoint.fromJson(Map<String, dynamic> json) {
    return PatrolCheckpoint(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      sequence: json['sequence'] as int,
      description: json['description'] as String?,
      qrPayload: json['qr_payload'] as String?,
    );
  }
}
