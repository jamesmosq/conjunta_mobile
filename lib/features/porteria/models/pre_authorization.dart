class PreAuthorization {
  const PreAuthorization({
    required this.id,
    required this.visitorName,
    this.documentType,
    this.document,
    required this.validFrom,
    required this.validUntil,
    this.purpose,
    required this.isActive,
  });

  factory PreAuthorization.fromJson(Map<String, dynamic> json) =>
      PreAuthorization(
        id: json['id'] as int,
        visitorName: json['visitor_name'] as String? ?? '',
        documentType: json['document_type'] as String?,
        document: json['document'] as String?,
        validFrom: json['valid_from'] as String? ?? '',
        validUntil: json['valid_until'] as String? ?? '',
        purpose: json['purpose'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final String visitorName;
  final String? documentType;
  final String? document;
  final String validFrom;
  final String validUntil;
  final String? purpose;
  final bool isActive;
}
