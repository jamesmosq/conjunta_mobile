import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/parking_spot.dart';

final parkingRepositoryProvider = Provider<ParkingRepository>((ref) {
  return ParkingRepository(ref.read(apiClientProvider).dio);
});

class ParkingRepository {
  ParkingRepository(this._dio);

  final Dio _dio;

  Future<List<ParkingSpot>> getSpots() async {
    final response = await _dio.get('/parking-spots');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => ParkingSpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Espacios del copropietario autenticado — el backend fuerza el filtro a
  /// su propio apartamento, sin importar qué se envíe (ver
  /// ParkingSpotController::index).
  Future<List<ParkingSpot>> getMySpots() => getSpots();

  /// Espacios libres para reclamar ("bolsa" de visitantes/liberados) — usa
  /// el endpoint de disponibilidad (accesible a todos salvo contratista),
  /// ya que el copropietario no puede listar el parqueadero de otros vía
  /// /parking-spots directo.
  Future<List<ParkingSpot>> getAvailableToClaim() async {
    final response = await _dio.get('/parking-spots/availability');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    final list = data['available_spots'] as List? ?? [];
    return list
        .map((e) => ParkingSpot.fromJson({
              ...e as Map<String, dynamic>,
              'is_available': true,
              'is_enabled': true,
            }))
        .toList();
  }

  Future<ParkingSpot> assign(int spotId, int visitId) async {
    final response = await _dio.patch(
      '/parking-spots/$spotId/assign',
      data: {'visit_id': visitId},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ParkingSpot.fromJson(data);
  }

  Future<ParkingSpot> release(int spotId) async {
    final response = await _dio.post('/parking-spots/$spotId/release');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ParkingSpot.fromJson(data);
  }

  /// [reason]: 'no_vehicle' (no tiene vehículo hoy) o 'vehicle_out' (el
  /// vehículo salió) — RF-USR Fase 3.
  Future<ParkingSpot> vacate(int spotId, String reason) async {
    final response = await _dio.post(
      '/parking-spots/$spotId/vacate',
      data: {'reason': reason},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ParkingSpot.fromJson(data);
  }

  Future<ParkingSpot> occupy(int spotId) async {
    final response = await _dio.post('/parking-spots/$spotId/occupy');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ParkingSpot.fromJson(data);
  }

  /// RF-USR Fase 5: reclama un espacio liberado — "primero que llega, se lo
  /// queda". El copropietario no envía apartmentId (el backend lo resuelve
  /// de su sesión); solo el administrador lo indica explícitamente.
  Future<ParkingSpot> claim(int spotId) async {
    final response = await _dio.post('/parking-spots/$spotId/claim');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return ParkingSpot.fromJson(data);
  }
}
