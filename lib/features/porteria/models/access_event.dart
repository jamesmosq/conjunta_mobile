class AccessEvent {
  const AccessEvent({
    required this.visitorName,
    this.documentType,
    this.document,
    required this.entryAt,
    this.registeredByName,
    this.apartmentNumber,
  });

  factory AccessEvent.fromJson(Map<String, dynamic> json) => AccessEvent(
        visitorName: (json['visitor_name'] as String?) ?? 'Visitante',
        documentType: json['document_type'] as String?,
        document: json['document'] as String?,
        entryAt: (json['entry_at'] as String?) ?? DateTime.now().toIso8601String(),
        registeredByName: json['registered_by_name'] as String?,
        apartmentNumber: json['apartment_number'] as String?,
      );

  final String visitorName;
  final String? documentType;
  final String? document;
  final String entryAt;
  final String? registeredByName;
  final String? apartmentNumber;

  DateTime get entryDateTime {
    try {
      return DateTime.parse(entryAt).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
