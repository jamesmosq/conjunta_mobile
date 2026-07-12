class BlacklistEntry {
  const BlacklistEntry({
    required this.id,
    required this.name,
    required this.documentNumber,
    this.apartmentId,
  });

  final int id;
  final String name;
  final String documentNumber;
  final int? apartmentId;

  factory BlacklistEntry.fromJson(Map<String, dynamic> json) =>
      BlacklistEntry(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        documentNumber: json['document_number'] as String? ?? '',
        apartmentId: json['apartment_id'] as int?,
      );
}
