import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/booking.dart';
import '../models/common_area.dart';

final areasRepositoryProvider = Provider<AreasRepository>((ref) {
  return AreasRepository(ref.read(apiClientProvider).dio);
});

class AreasRepository {
  AreasRepository(this._dio);
  final Dio _dio;

  Future<List<CommonArea>> getAreas() async {
    final response = await _dio.get('/common-areas');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => CommonArea.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommonArea> getArea(int id) async {
    final response = await _dio.get('/common-areas/$id');
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CommonArea.fromJson(json);
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _dio.get('/my/bookings');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> createBooking(int areaId, Map<String, dynamic> data) async {
    final response =
        await _dio.post('/common-areas/$areaId/bookings', data: data);
    final raw = response.data;
    final json = raw is Map && raw.containsKey('data')
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return Booking.fromJson(json);
  }

  Future<void> cancelBooking(int id, String reason) async {
    await _dio.post('/bookings/$id/cancel', data: {'reason': reason});
  }

  Future<List<Booking>> getAreaAvailability(
      int areaId, String date) async {
    final response = await _dio
        .get('/common-areas/$areaId/availability', queryParameters: {'date': date});
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
