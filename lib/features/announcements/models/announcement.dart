class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.importance,
    this.category,
    this.author,
    required this.createdAt,
    this.readAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        importance: json['importance'] as String? ?? 'normal',
        category: json['category'] as String?,
        author: json['author'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        readAt: json['read_at'] as String?,
      );

  final int id;
  final String title;
  final String body;
  final String importance; // 'urgent' | 'normal' | 'info'
  final String? category;
  final String? author;
  final String createdAt;
  final String? readAt;

  bool get isRead => readAt != null;
  bool get isUrgent => importance == 'urgent';

  String get categoryLabel => switch (category) {
        'financial' => 'Financiero',
        'maintenance' => 'Mantenimiento',
        'security' => 'Seguridad',
        'social' => 'Social',
        'assembly' => 'Asamblea',
        _ => category ?? 'General',
      };

  Announcement copyWith({String? readAt}) => Announcement(
        id: id,
        title: title,
        body: body,
        importance: importance,
        category: category,
        author: author,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}
