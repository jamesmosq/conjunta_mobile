class CommonArea {
  const CommonArea({
    required this.id,
    required this.name,
    this.description,
    this.capacity,
    this.openTime,
    this.closeTime,
    this.advanceDays,
    this.feePerHour,
    this.rules,
    this.isActive = true,
  });

  factory CommonArea.fromJson(Map<String, dynamic> json) => CommonArea(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        capacity: json['capacity'] as int?,
        openTime: json['open_time'] as String?,
        closeTime: json['close_time'] as String?,
        advanceDays: json['advance_days'] as int?,
        feePerHour: (json['fee_per_hour'] as num?)?.toDouble(),
        rules: json['rules'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final String name;
  final String? description;
  final int? capacity;
  final String? openTime;
  final String? closeTime;
  final int? advanceDays;
  final double? feePerHour;
  final String? rules;
  final bool isActive;
}
