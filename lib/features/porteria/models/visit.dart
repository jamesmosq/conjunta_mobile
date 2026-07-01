class Visit {
  const Visit({
    required this.id,
    required this.visitorName,
    this.documentType,
    this.document,
    this.entryAt,
    this.exitAt,
    required this.status,
    this.apartmentId,
    this.registeredByName,
  });

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as int,
        visitorName: json['visitor_name'] as String? ?? '',
        documentType: json['document_type'] as String?,
        document: json['document'] as String?,
        entryAt: json['entry_at'] as String?,
        exitAt: json['exit_at'] as String?,
        status: json['status'] as String? ?? 'active',
        apartmentId: json['apartment_id'] as int?,
        registeredByName: json['registered_by_name'] as String?,
      );

  final int id;
  final String visitorName;
  final String? documentType;
  final String? document;
  final String? entryAt;
  final String? exitAt;
  final String status;
  final int? apartmentId;
  final String? registeredByName;

  bool get isActive => exitAt == null;
}
