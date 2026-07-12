class QrPreview {
  const QrPreview({
    required this.uuid,
    required this.nombre,
    required this.tipoDocumento,
    required this.documento,
    this.placa,
    this.apartamento,
    required this.validoHasta,
  });

  final String uuid;
  final String nombre;
  final String tipoDocumento;
  final String documento;
  final String? placa;
  final String? apartamento;
  final String validoHasta;

  String get tipoDocumentoLabel => switch (tipoDocumento) {
        'cc' => 'Cédula de Ciudadanía',
        'pasaporte' => 'Pasaporte',
        'ce' => 'Cédula de Extranjería',
        _ => tipoDocumento.toUpperCase(),
      };

  factory QrPreview.fromJson(Map<String, dynamic> json) {
    final visitante = json['visitante'] as Map<String, dynamic>? ?? {};
    return QrPreview(
      uuid: json['uuid'] as String? ?? '',
      nombre: visitante['nombre'] as String? ?? '',
      tipoDocumento: visitante['tipo_documento'] as String? ?? '',
      documento: visitante['documento'] as String? ?? '',
      placa: visitante['placa'] as String?,
      apartamento: json['apartamento'] as String?,
      validoHasta: json['valido_hasta']?.toString() ?? '',
    );
  }
}
