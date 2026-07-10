/// Laravel serializa columnas `decimal:N` como String en JSON (para no
/// perder precisión), así que un simple `json['x'] as num?` revienta con
/// un TypeError apenas el backend manda "50000.00" en vez de 50000.0.
/// Estos helpers aceptan num o String indistintamente.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt();
}
