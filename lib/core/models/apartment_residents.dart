/// Un apartamento con los nombres de sus residentes activos — usado por el
/// directorio de residentes de portería (QA #35). Deliberadamente no incluye
/// correo/teléfono: el backend ya los oculta para el rol portero (Ley 1581),
/// así que ni siquiera llegarían en la respuesta.
class ApartmentResidents {
  const ApartmentResidents({
    required this.id,
    required this.number,
    this.tower,
    required this.fullIdentifier,
    required this.residentNames,
  });

  final int id;
  final String number;
  final String? tower;
  final String fullIdentifier;
  final List<String> residentNames;

  factory ApartmentResidents.fromJson(Map<String, dynamic> json) {
    final residents = (json['residents'] as List? ?? [])
        .map((r) => (r as Map<String, dynamic>)['user'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((u) => u['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return ApartmentResidents(
      id: json['id'] as int,
      number: json['number'] as String? ?? '',
      tower: json['tower'] as String?,
      fullIdentifier:
          json['full_identifier'] as String? ?? json['number'] as String? ?? '',
      residentNames: residents,
    );
  }
}
