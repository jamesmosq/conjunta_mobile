class Package {
  const Package({
    required this.id,
    this.description,
    required this.arrivedAt,
    this.deliveredAt,
    this.deliveredToName,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        id: json['id'] as int,
        description: json['description'] as String?,
        arrivedAt: json['arrived_at'] as String? ?? '',
        deliveredAt: json['delivered_at'] as String?,
        deliveredToName: json['delivered_to_name'] as String?,
      );

  final int id;
  final String? description;
  final String arrivedAt;
  final String? deliveredAt;
  final String? deliveredToName;

  bool get isPending => deliveredAt == null;
}
