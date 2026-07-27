class QrVisitante {
  const QrVisitante({
    required this.nombre,
    required this.tipoDocumento,
    required this.documento,
    this.placa,
  });

  final String nombre;
  final String tipoDocumento;
  final String documento;
  final String? placa;

  factory QrVisitante.fromJson(Map<String, dynamic> json) {
    return QrVisitante(
      nombre: json['nombre'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String? ?? '',
      documento: json['documento'] as String? ?? '',
      placa: json['placa'] as String?,
    );
  }

  String get tipoDocumentoLabel => switch (tipoDocumento) {
        'cc' => 'Cédula de Ciudadanía',
        'pasaporte' => 'Pasaporte',
        'ce' => 'Cédula de Extranjería',
        _ => tipoDocumento.toUpperCase(),
      };
}

class VisitQrCode {
  const VisitQrCode({
    required this.id,
    required this.uuid,
    required this.qrUrl,
    this.codigo,
    required this.visitante,
    required this.apartamentoId,
    this.apartamentoNumero,
    this.autorizadoPor,
    required this.validoDesde,
    this.validoHasta,
    this.esPermanente = false,
    required this.estado,
    required this.createdAt,
    this.usadoEn,
    this.revocadoEn,
    this.visitaId,
  });

  final int id;
  final String uuid;
  final String qrUrl;
  /// Código corto de 4 dígitos — alternativa al QR para que el portero
  /// registre la visita manualmente si el visitante no puede mostrar el QR.
  final String? codigo;
  final QrVisitante visitante;
  final int apartamentoId;
  final String? apartamentoNumero;
  /// Quién generó la invitación (el residente autenticado) — se muestra para
  /// que el residente y portería puedan verificar quién la autorizó.
  final String? autorizadoPor;
  final String validoDesde;
  final String? validoHasta;
  /// Código/QR permanente (recurrente, sin vencimiento) — no se invalida por
  /// uso, a diferencia del QR temporal de un solo uso.
  final bool esPermanente;
  final String estado;
  final String createdAt;
  final String? usadoEn;
  final String? revocadoEn;
  final int? visitaId;

  bool get isActivo => estado == 'activo';
  bool get isPermanente => estado == 'permanente';
  bool get isUsado => estado == 'usado';
  bool get isExpirado => estado == 'expirado';
  bool get isRevocado => estado == 'revocado';
  bool get canRevoke => isActivo || isPermanente;

  factory VisitQrCode.fromJson(Map<String, dynamic> json) {
    final apartamento = json['apartamento'] as Map<String, dynamic>?;
    final creadoPor = json['creado_por'] as Map<String, dynamic>?;

    return VisitQrCode(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      qrUrl: json['qr_url'] as String? ?? '',
      codigo: json['codigo'] as String?,
      visitante: QrVisitante.fromJson(
          json['visitante'] as Map<String, dynamic>? ?? {}),
      apartamentoId: json['apartamento_id'] as int? ?? 0,
      apartamentoNumero: apartamento?['numero'] as String?,
      autorizadoPor: creadoPor?['nombre'] as String?,
      validoDesde: json['valido_desde']?.toString() ?? '',
      validoHasta: json['valido_hasta']?.toString(),
      esPermanente: json['permanente'] as bool? ?? false,
      estado: json['estado'] as String? ?? 'activo',
      createdAt: json['created_at']?.toString() ?? '',
      usadoEn: json['usado_en']?.toString(),
      revocadoEn: json['revocado_en']?.toString(),
      visitaId: json['visita_id'] as int?,
    );
  }
}
