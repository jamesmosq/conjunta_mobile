class ApartmentLookup {
  const ApartmentLookup({
    required this.id,
    required this.number,
    this.tower,
    required this.fullIdentifier,
  });

  final int id;
  final String number;
  final String? tower;
  final String fullIdentifier;

  factory ApartmentLookup.fromJson(Map<String, dynamic> json) =>
      ApartmentLookup(
        id: json['id'] as int,
        number: json['number'] as String? ?? '',
        tower: json['tower'] as String?,
        fullIdentifier: json['full_identifier'] as String? ??
            json['number'] as String? ??
            '',
      );
}
