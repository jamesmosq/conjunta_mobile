class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.importance,
    this.category,
    this.author,
    required this.createdAt,
    this.read = false,
  });

  // AnnouncementResource (backend) no manda `importance`/`category`/`read_at`
  // — manda `is_urgent` (bool) y `read` (bool). Antes este parser buscaba
  // esos campos inexistentes y siempre caía a los valores por defecto: todo
  // comunicado se veía "normal" y "no leído" para siempre, sin importar su
  // urgencia real ni que el usuario ya lo hubiera abierto.
  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        importance: (json['is_urgent'] as bool? ?? false) ? 'urgent' : 'normal',
        category: json['category'] as String?,
        author: json['author'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        read: json['read'] as bool? ?? false,
      );

  final int id;
  final String title;
  final String body;
  final String importance; // 'urgent' | 'normal' | 'info'
  final String? category;
  final String? author;
  final String createdAt;
  final bool read;

  bool get isRead => read;
  bool get isUrgent => importance == 'urgent';

  String get categoryLabel => switch (category) {
        'financial' => 'Financiero',
        'maintenance' => 'Mantenimiento',
        'security' => 'Seguridad',
        'social' => 'Social',
        'assembly' => 'Asamblea',
        _ => category ?? 'General',
      };

  Announcement copyWith({bool? read}) => Announcement(
        id: id,
        title: title,
        body: body,
        importance: importance,
        category: category,
        author: author,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
