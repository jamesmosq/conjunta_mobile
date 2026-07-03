import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(apiClientProvider).dio);
});

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<ChatConversation>> getConversations() async {
    final response = await _dio.get('/conversaciones');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? []) : (raw ?? []);
    return (list as List)
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<ChatMessage> messages, bool hasMore})> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await _dio.get(
      '/conversaciones/$conversationId/mensajes',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as List<dynamic>? ?? [];
    final meta = raw['meta'] as Map<String, dynamic>?;
    final currentPage = meta?['current_page'] as int? ?? page;
    final lastPage = meta?['last_page'] as int? ?? 1;

    final messages = data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    return (messages: messages, hasMore: currentPage < lastPage);
  }

  Future<ChatMessage> sendMessage({
    required int conversationId,
    String? texto,
    File? adjunto,
  }) async {
    FormData formData;
    if (adjunto != null) {
      final ext = adjunto.path.split('.').last.toLowerCase();
      formData = FormData.fromMap({
        if (texto != null && texto.isNotEmpty) 'texto': texto,
        'adjunto': await MultipartFile.fromFile(
          adjunto.path,
          filename: 'attachment_${DateTime.now().millisecondsSinceEpoch}.$ext',
        ),
      });
    } else {
      formData = FormData.fromMap({'texto': texto ?? ''});
    }

    final response = await _dio.post(
      '/conversaciones/$conversationId/mensajes',
      data: formData,
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ChatMessage.fromJson(data);
  }

  Future<void> markRead(int conversationId) async {
    await _dio.post('/conversaciones/$conversationId/mensajes/leer');
  }

  Future<int> startConversation({
    required int destinatarioId,
    required String mensaje,
  }) async {
    final response = await _dio.post('/conversaciones', data: {
      'destinatario_id': destinatarioId,
      'mensaje': mensaje,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return data['conversacion_id'] as int;
  }
}
