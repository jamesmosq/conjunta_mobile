import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/maintenance_request.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.read(apiClientProvider).dio);
});

class MaintenanceRepository {
  MaintenanceRepository(this._dio);
  final Dio _dio;

  Future<List<MaintenanceRequest>> getMyRequests() async {
    final response = await _dio.get('/damage-reports');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => MaintenanceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// BUG-07 (QA 11 ago 2026): antes solo enviaba JSON, sin forma de
  /// adjuntar fotos — el backend esperaba URLs que ningún flujo producía.
  /// Con [photos] presente se envía multipart (hasta 5 imágenes), igual
  /// que PatrolRepository.reportIncident().
  Future<MaintenanceRequest> createRequest(
    Map<String, dynamic> data, {
    List<File>? photos,
  }) async {
    final payload = (photos == null || photos.isEmpty)
        ? data
        : FormData.fromMap({
            ...data,
            'photos': [
              for (var i = 0; i < photos.length; i++)
                await MultipartFile.fromFile(
                  photos[i].path,
                  filename: 'reporte_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                ),
            ],
          });

    final response = await _dio.post('/maintenance-requests', data: payload);
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return MaintenanceRequest.fromJson(json);
  }

  Future<List<TimelineEntry>> getTimeline(int requestId) async {
    final response =
        await _dio.get('/damage-reports/$requestId/timeline');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
