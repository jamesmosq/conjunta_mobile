import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/announcement.dart';

final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.read(apiClientProvider).dio);
});

class AnnouncementsRepository {
  AnnouncementsRepository(this._dio);

  final Dio _dio;

  Future<({List<Announcement> items, bool hasMore})> getAnnouncements({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _dio.get(
      '/announcements',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (unreadOnly) 'unread': 1,
      },
    );
    final raw = response.data as Map<String, dynamic>;
    final list = (raw['data'] as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = raw['meta'] as Map<String, dynamic>?;
    final lastPage = (meta?['last_page'] as int?) ?? 1;
    return (items: list, hasMore: page < lastPage);
  }

  Future<void> markRead(int id) async {
    await _dio.post('/announcements/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/announcements/read-all');
  }
}
