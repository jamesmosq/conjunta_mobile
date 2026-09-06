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

  /// Bandeja de novedades — antes esta pantalla no existía en ningún lado:
  /// un portero entrando de relevo no tenía forma de ver qué había pasado en
  /// el turno anterior, aunque el backend siempre guardó el historial.
  Future<List<ShiftIncident>> getIncidents({String? urgency}) async {
    final response = await _dio.get('/shift-incidents', queryParameters: {
      if (urgency != null && urgency.isNotEmpty) 'urgency': urgency,
    });
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List;
    return list
        .map((e) => ShiftIncident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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
