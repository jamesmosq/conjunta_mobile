import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/maintenance_request.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.read(apiClientProvider).dio);
});

class MaintenanceRepository {
  MaintenanceRepository(this._dio);
  final Dio _dio;

  Future<List<MaintenanceRequest>> getMyRequests() async {
    final response = await _dio.get('/maintenance-requests');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => MaintenanceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MaintenanceRequest> createRequest(
    Map<String, dynamic> data, {
    List<XFile> photos = const [],
  }) async {
    late final Response<dynamic> response;

    if (photos.isEmpty) {
      response = await _dio.post('/maintenance-requests', data: data);
    } else {
      final formData = FormData.fromMap({
        ...data.map((k, v) => MapEntry(k, v?.toString())),
        'photos[]': await Future.wait(
          photos.map((f) async => MultipartFile.fromFileSync(
                f.path,
                filename: f.name,
              )),
        ),
      });
      response = await _dio.post(
        '/maintenance-requests',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    }

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
