import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/blacklist_entry.dart';

final blacklistRepositoryProvider = Provider<BlacklistRepository>((ref) {
  return BlacklistRepository(ref.read(apiClientProvider).dio);
});

class BlacklistRepository {
  BlacklistRepository(this._dio);

  final Dio _dio;

  Future<List<BlacklistEntry>> getList() async {
    final response = await _dio.get('/blacklist');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => BlacklistEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
