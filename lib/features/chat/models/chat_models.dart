class ChatAttachment {
  const ChatAttachment({required this.url, required this.tipo});

  final String url;
  final String tipo;

  bool get isImage =>
      tipo == 'image' || url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png');
  bool get isPdf => tipo == 'pdf' || url.endsWith('.pdf');

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      url: json['url'] as String,
      tipo: json['tipo'] as String? ?? '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.remitenteId,
    required this.remitentNombre,
    required this.sentAt,
    this.texto,
    this.adjunto,
    this.readAt,
  });

  final int id;
  final int remitenteId;
  final String remitentNombre;
  final String sentAt;
  final String? texto;
  final ChatAttachment? adjunto;
  final String? readAt;

  bool get isRead => readAt != null;

  ChatMessage copyWithReadAt(String readAt) {
    return ChatMessage(
      id: id,
      remitenteId: remitenteId,
      remitentNombre: remitentNombre,
      sentAt: sentAt,
      texto: texto,
      adjunto: adjunto,
      readAt: readAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final adjuntoData = json['adjunto'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as int,
      remitenteId: json['remitente_id'] as int,
      remitentNombre: json['remitente_nombre'] as String? ?? '',
      sentAt: json['enviado_en']?.toString() ?? '',
      texto: json['texto'] as String?,
      adjunto: adjuntoData != null ? ChatAttachment.fromJson(adjuntoData) : null,
      readAt: json['leido_en']?.toString(),
    );
  }

  /// Builds from Reverb `message.sent` broadcast payload (English fields).
  factory ChatMessage.fromReverbData(Map<String, dynamic> data) {
    ChatAttachment? adjunto;
    final attachUrl = data['attachment_url'] as String?;
    final attachType = data['attachment_type'] as String?;
    if (attachUrl != null && attachUrl.isNotEmpty) {
      adjunto = ChatAttachment(url: attachUrl, tipo: attachType ?? '');
    }
    return ChatMessage(
      id: data['id'] as int,
      remitenteId: data['sender_id'] as int,
      remitentNombre: data['sender_name'] as String? ?? '',
      sentAt: data['sent_at']?.toString() ?? DateTime.now().toIso8601String(),
      texto: data['body'] as String?,
      adjunto: adjunto,
      readAt: null,
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.unreadCount,
    this.contraparte,
    this.ultimoMensaje,
    this.lastMessageAt,
  });

  final int id;
  final int unreadCount;
  final Map<String, dynamic>? contraparte;
  final Map<String, dynamic>? ultimoMensaje;
  final String? lastMessageAt;

  String get contraparteName =>
      contraparte?['name'] as String? ?? 'Administrador';

  String get lastMessagePreview {
    final texto = ultimoMensaje?['texto'] as String?;
    if (texto != null && texto.isNotEmpty) return texto;
    return '📎 Archivo adjunto';
  }

  bool get lastMessageRead => ultimoMensaje?['leido'] as bool? ?? true;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      unreadCount: json['mensajes_sin_leer'] as int? ?? 0,
      contraparte: json['contraparte'] as Map<String, dynamic>?,
      ultimoMensaje: json['ultimo_mensaje'] as Map<String, dynamic>?,
      lastMessageAt: json['last_message_at']?.toString(),
    );
  }
}
