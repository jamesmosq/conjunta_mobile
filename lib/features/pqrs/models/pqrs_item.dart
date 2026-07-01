class PqrsItem {
  const PqrsItem({
    required this.id,
    required this.radicadoNumber,
    required this.type,
    required this.subject,
    required this.description,
    required this.status,
    this.response,
    this.respondedAt,
    this.closedAt,
    this.dueDate,
    required this.createdAt,
  });

  factory PqrsItem.fromJson(Map<String, dynamic> json) => PqrsItem(
        id: json['id'] as int,
        radicadoNumber: json['radicado_number'] as String? ?? '#${json['id']}',
        type: json['type'] as String? ?? 'petition',
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        response: json['response'] as String?,
        respondedAt: json['responded_at'] as String?,
        closedAt: json['closed_at'] as String?,
        dueDate: json['due_date'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  final int id;
  final String radicadoNumber;
  final String type;
  final String subject;
  final String description;
  final String status;
  final String? response;
  final String? respondedAt;
  final String? closedAt;
  final String? dueDate;
  final String createdAt;

  bool get isAnswered =>
      status == 'responded' || status == 'closed';

  bool get isDueOverdue {
    if (dueDate == null || isAnswered) return false;
    try {
      return DateTime.parse(dueDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String get typeLabel => switch (type) {
        'petition' => 'Petición',
        'complaint' => 'Queja',
        'claim' => 'Reclamo',
        'suggestion' => 'Sugerencia',
        _ => type,
      };

  String get statusLabel => switch (status) {
        'pending' => 'Pendiente',
        'in_progress' => 'En trámite',
        'responded' => 'Respondida',
        'closed' => 'Cerrada',
        _ => status,
      };
}
