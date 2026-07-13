import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/staff_badge.dart';

final staffBadgeRepositoryProvider = Provider<StaffBadgeRepository>((ref) {
  return StaffBadgeRepository(ref.read(apiClientProvider).dio);
});

class StaffBadgeRepository {
  StaffBadgeRepository(this._dio);

  final Dio _dio;

  Future<StaffBadge> getMyBadge() async {
    final response = await _dio.get('/staff-badge');
    final raw = response.data as Map<String, dynamic>;
    return StaffBadge.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<StaffBadge> regenerate() async {
    final response = await _dio.post('/staff-badge/regenerar');
    final raw = response.data as Map<String, dynamic>;
    return StaffBadge.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<StaffBadge> previewByCode(String code) async {
    final response = await _dio.get('/staff-badge/codigo/$code');
    final raw = response.data as Map<String, dynamic>;
    return StaffBadge.fromJson(raw['data'] as Map<String, dynamic>);
  }

  /// Marca entrada o salida. Sin `direction`, el backend alterna
  /// automáticamente según el último evento registrado para esa persona.
  Future<String> markByCode(String code, {String? direction}) async {
    final response = await _dio.post(
      '/staff-badge/codigo/$code/marcar',
      data: direction != null ? {'direction': direction} : null,
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return data['direction'] as String? ?? 'entrada';
  }
}
