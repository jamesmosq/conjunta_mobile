import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/work_order.dart';

final contractorRepositoryProvider = Provider<ContractorRepository>((ref) {
  return ContractorRepository(ref.read(apiClientProvider).dio);
});

class ContractorRepository {
  ContractorRepository(this._dio);
  final Dio _dio;

  Future<List<WorkOrder>> getActiveOrders() async {
    final response = await _dio.get('/contractor/work-orders');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkOrder>> getHistory() async {
    final response = await _dio.get('/contractor/work-orders/history');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkOrder> acceptOrder(int id, String estimatedArrivalAt) async {
    final response = await _dio.post(
      '/contractor/work-orders/$id/accept',
      data: {'estimated_arrival_at': estimatedArrivalAt},
    );
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return WorkOrder.fromJson(json);
  }

  Future<WorkOrder> goOnTheWay(int id) async {
    final response =
        await _dio.post('/contractor/work-orders/$id/on-the-way');
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return WorkOrder.fromJson(json);
  }

  Future<List<WorkOrderMaterial>> getMaterials(int workOrderId) async {
    final response =
        await _dio.get('/contractor/work-orders/$workOrderId/materials');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => WorkOrderMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMaterials(
      int workOrderId, List<Map<String, dynamic>> materials) async {
    await _dio.post(
      '/contractor/work-orders/$workOrderId/materials',
      data: {'materials': materials},
    );
  }
}
