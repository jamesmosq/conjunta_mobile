import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/shift_incident.dart';

final shiftIncidentRepositoryProvider = Provider<ShiftIncidentRepository>((ref) {
  return ShiftIncidentRepository(ref.read(apiClientProvider).dio);
});

class ShiftIncidentRepository {
  ShiftIncidentRepository(this._dio);

  final Dio _dio;

  Future<ShiftIncident> create({
    required String description,
    required String category,
    required String urgency,
  }) async {
    final response = await _dio.post('/shift-incidents', data: {
      'description': description,
      'category': category,
      'urgency': urgency,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ShiftIncident.fromJson(data);
  }
}
