import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/user_notification.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(apiClientProvider).dio);
});

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<List<UserNotification>> getNotifications({int page = 1}) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'per_page': 20, 'page': page},
    );
    final data = response.data;
    final List<dynamic> list = data is Map
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>;
    return list
        .map((e) => UserNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
