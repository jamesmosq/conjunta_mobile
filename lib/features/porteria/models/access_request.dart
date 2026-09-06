class AccessRequest {
  const AccessRequest({
    required this.id,
    this.apartmentNumber,
    this.requestedByName,
    this.respondedByName,
    required this.visitorName,
    this.documentNumber,
    this.reason,
    required this.status,
    this.respondedAt,
    required this.expiresAt,
  });

  factory AccessRequest.fromJson(Map<String, dynamic> json) {
    final apartamento = json['apartamento'] as Map<String, dynamic>?;
    final solicitadoPor = json['solicitado_por'] as Map<String, dynamic>?;
    final respondidoPor = json['respondido_por'] as Map<String, dynamic>?;

    return AccessRequest(
      id: json['id'] as int,
      apartmentNumber: apartamento?['numero'] as String?,
      requestedByName: solicitadoPor?['nombre'] as String?,
      respondedByName: respondidoPor?['nombre'] as String?,
      visitorName: json['visitor_name'] as String? ?? '',
      documentNumber: json['document_number'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      respondedAt: json['responded_at'] as String?,
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }

  final int id;
  final String? apartmentNumber;
  final String? requestedByName;
  final String? respondedByName;
  final String visitorName;
  final String? documentNumber;
  final String? reason;
  final String status;
  final String? respondedAt;
  final String expiresAt;

  bool get isPending => status == 'pending';

  DateTime? get expiresAtDateTime {
    try {
      return DateTime.parse(expiresAt).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get statusLabel => switch (status) {
        'approved' => 'Aprobado',
        'rejected' => 'Rechazado',
        'expired' => 'Sin respuesta',
        _ => 'Pendiente',
      };

  AccessRequest copyWith({String? status, String? respondedByName}) =>
      AccessRequest(
        id: id,
        apartmentNumber: apartmentNumber,
        requestedByName: requestedByName,
        respondedByName: respondedByName ?? this.respondedByName,
        visitorName: visitorName,
        documentNumber: documentNumber,
        reason: reason,
        status: status ?? this.status,
        respondedAt: respondedAt,
        expiresAt: expiresAt,
      );
}
