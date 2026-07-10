import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/pqrs_item.dart';

final pqrsRepositoryProvider = Provider<PqrsRepository>((ref) {
  return PqrsRepository(ref.read(apiClientProvider).dio);
});

class PqrsRepository {
  PqrsRepository(this._dio);

  final Dio _dio;

  Future<List<PqrsItem>> getMyPqrs() async {
    final response = await _dio.get('/pqrs');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => PqrsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PqrsItem> createPqrs(Map<String, dynamic> data) async {
    final response = await _dio.post('/pqrs', data: data);
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PqrsItem.fromJson(json);
  }
}
