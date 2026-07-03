import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/patrol_route.dart';
import '../models/patrol_session.dart';

final patrolRepositoryProvider = Provider<PatrolRepository>((ref) {
  return PatrolRepository(ref.read(apiClientProvider).dio);
});

class PatrolRepository {
  PatrolRepository(this._dio);

  final Dio _dio;

  Future<List<PatrolRoute>> getRoutes() async {
    final response = await _dio.get('/rutas-ronda');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? []) : (raw ?? []);
    return (list as List)
        .map((e) => PatrolRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatrolSession> startSession(int routeId) async {
    final response = await _dio.post('/rondas/iniciar', data: {'route_id': routeId});
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return PatrolSession.fromJson(data);
  }

  Future<PatrolSession> getSession(int sessionId) async {
    final response = await _dio.get('/rondas/$sessionId');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return PatrolSession.fromJson(data);
  }

  Future<int> scanCheckpoint({
    required int sessionId,
    required String uuid,
    required String token,
    String? notes,
  }) async {
    final response = await _dio.post('/rondas/$sessionId/checkpoint', data: {
      'uuid': uuid,
      'token': token,
      if (notes != null) 'notes': notes,
    });
    final raw = response.data as Map<String, dynamic>;
    return raw['log_id'] as int? ?? 0;
  }

  Future<int> reportIncident({
    required int sessionId,
    required String description,
    required String severity,
    int? checkpointId,
    File? photo,
  }) async {
    FormData formData;
    if (photo != null) {
      formData = FormData.fromMap({
        'description': description,
        'severity': severity,
        if (checkpointId != null) 'checkpoint_id': checkpointId,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'incident_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
    } else {
      formData = FormData.fromMap({
        'description': description,
        'severity': severity,
        if (checkpointId != null) 'checkpoint_id': checkpointId,
      });
    }

    final response = await _dio.post(
      '/rondas/$sessionId/incidencia',
      data: formData,
    );
    final raw = response.data as Map<String, dynamic>;
    return raw['incident_id'] as int? ?? 0;
  }

  Future<PatrolSession> finishSession(int sessionId, {String? notes}) async {
    final response = await _dio.post('/rondas/$sessionId/finalizar', data: {
      if (notes != null) 'notes': notes,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return PatrolSession.fromJson(data);
  }
}
