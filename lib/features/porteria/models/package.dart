class Package {
  const Package({
    required this.id,
    this.description,
    this.sender,
    required this.arrivedAt,
    this.deliveredAt,
    this.deliveredToName,
    this.authorizedBy,
    this.authorizationMethod,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        id: json['id'] as int,
        description: json['description'] as String?,
        sender: json['sender'] as String?,
        arrivedAt: json['received_at'] as String? ?? json['arrived_at'] as String? ?? '',
        deliveredAt: json['delivered_at'] as String?,
        deliveredToName: json['delivered_to'] as String? ?? json['delivered_to_name'] as String?,
        authorizedBy: json['authorized_by'] as String?,
        authorizationMethod: json['authorization_method'] as String?,
      );

  final int id;
  final String? description;
  final String? sender;
  final String arrivedAt;
  final String? deliveredAt;
  final String? deliveredToName;
  final String? authorizedBy;
  final String? authorizationMethod;

  bool get isPending => deliveredAt == null;
}
