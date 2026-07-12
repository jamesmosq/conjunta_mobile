import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final manualVisitRepositoryProvider = Provider<ManualVisitRepository>((ref) {
  return ManualVisitRepository(ref.read(apiClientProvider).dio);
});

class ManualVisitResult {
  const ManualVisitResult({
    required this.visitorName,
    required this.blacklisted,
    required this.parkingAssigned,
    this.alert,
  });

  final String visitorName;
  final bool blacklisted;
  final bool parkingAssigned;
  final String? alert;
}

class ManualVisitRepository {
  ManualVisitRepository(this._dio);

  final Dio _dio;

  Future<ManualVisitResult> create({
    required String visitorName,
    required int apartmentId,
    String? documentNumber,
    String? accessType,
    String? vehiclePlate,
    String? vehicleType,
  }) async {
    final response = await _dio.post('/visits', data: {
      'visitor_name': visitorName,
      'apartment_id': apartmentId,
      if (documentNumber != null && documentNumber.isNotEmpty)
        'document_number': documentNumber,
      if (accessType != null) 'access_type': accessType,
      if (vehiclePlate != null && vehiclePlate.isNotEmpty)
        'vehicle_plate': vehiclePlate,
      if (vehicleType != null) 'vehicle_type': vehicleType,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return ManualVisitResult(
      visitorName: data['visitor_name'] as String? ?? visitorName,
      blacklisted: raw['blacklisted'] as bool? ?? false,
      parkingAssigned: raw['parking_assigned'] as bool? ?? false,
      alert: raw['alert'] as String?,
    );
  }
}
