class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.sequence,
    this.options,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        sequence: json['sequence'] as int? ?? 0,
        options: (json['options'] as List?)?.map((e) => e as String).toList(),
      );

  final int id;
  final String text;
  final String type; // 'single' | 'multiple' | 'text'
  final int sequence;
  final List<String>? options;

  bool get isSingle => type == 'single';
  bool get isMultiple => type == 'multiple';
  bool get isText => type == 'text';

  String get typeLabel => switch (type) {
        'single' => 'Opción única',
        'multiple' => 'Opción múltiple',
        _ => 'Texto libre',
      };
}

class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.status,
    required this.isAnonymous,
    this.description,
    this.closesAt,
    this.createdAt,
    this.questions,
  });

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'draft',
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        closesAt: json['closes_at'] as String?,
        createdAt: json['created_at'] as String?,
        questions: (json['questions'] as List?)
            ?.map((e) => SurveyQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String title;
  final String? description;
  final String status; // 'draft' | 'active' | 'closed'
  final bool isAnonymous;
  final String? closesAt;
  final String? createdAt;
  final List<SurveyQuestion>? questions;

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  DateTime? get closesAtDate =>
      closesAt != null ? DateTime.tryParse(closesAt!) : null;

  String get statusLabel => switch (status) {
        'active' => 'Activa',
        'closed' => 'Cerrada',
        _ => 'Borrador',
      };
}
