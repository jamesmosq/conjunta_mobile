class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      UserNotification(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  bool get isRead => readAt != null;

  UserNotification copyWith({String? readAt}) => UserNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}
