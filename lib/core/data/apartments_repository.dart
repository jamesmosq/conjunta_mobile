import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/apartment_lookup.dart';
import '../network/api_client.dart';

final apartmentsRepositoryProvider = Provider<ApartmentsRepository>((ref) {
  return ApartmentsRepository(ref.read(apiClientProvider).dio);
});

class ApartmentsRepository {
  ApartmentsRepository(this._dio);

  final Dio _dio;

  Future<List<ApartmentLookup>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get(
      '/apartments',
      queryParameters: {'search': query.trim()},
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => ApartmentLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
