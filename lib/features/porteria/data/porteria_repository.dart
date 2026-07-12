import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/package.dart';
import '../models/pre_authorization.dart';
import '../models/visit.dart';

final porteriaRepositoryProvider = Provider<PorteriaRepository>((ref) {
  return PorteriaRepository(ref.read(apiClientProvider).dio);
});

class PorteriaRepository {
  PorteriaRepository(this._dio);
  final Dio _dio;

  Future<List<Visit>> getVisits() async {
    final response = await _dio.get('/visits');
    final raw = response.data;
    final list = raw is Map ? raw['data'] : raw;
    return (list as List).map((e) => Visit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PreAuthorization>> getPreAuthorizations(int apartmentId) async {
    final response = await _dio.get('/apartments/$apartmentId/pre-authorizations');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => PreAuthorization.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PreAuthorization> createPreAuthorization(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/pre-authorizations', data: data);
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PreAuthorization.fromJson(json);
  }

  Future<void> deletePreAuthorization(int id) async {
    await _dio.delete('/pre-authorizations/$id');
  }

  Future<({List<Visit> visits, bool hasMore})> getVisitHistory({
    int page = 1,
    int perPage = 20,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      '/visits/history',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
    );
    final raw = response.data as Map<String, dynamic>;
    final list = (raw['data'] as List)
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = raw['meta'] as Map<String, dynamic>?;
    final lastPage = (meta?['last_page'] as int?) ?? 1;
    return (visits: list, hasMore: page < lastPage);
  }

  Future<List<Package>> getPackages() async {
    final response = await _dio.get('/packages');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => Package.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Package> deliverPackage(int id, String deliveredTo) async {
    final response = await _dio.post(
      '/packages/$id/deliver',
      data: {'delivered_to': deliveredTo},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return Package.fromJson(data);
  }

  Future<Package> createPackage({
    required int apartmentId,
    required String description,
    String? sender,
  }) async {
    final response = await _dio.post('/packages', data: {
      'apartment_id': apartmentId,
      'description': description,
      if (sender != null && sender.isNotEmpty) 'sender': sender,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return Package.fromJson(data);
  }

  Future<Visit> exitVisit(int visitId) async {
    final response = await _dio.post('/visits/$visitId/exit');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return Visit.fromJson(data);
  }
}
