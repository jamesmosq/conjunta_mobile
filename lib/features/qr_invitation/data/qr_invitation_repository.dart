import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/visit_qr_code.dart';

final qrInvitationRepositoryProvider = Provider<QrInvitationRepository>((ref) {
  return QrInvitationRepository(ref.read(apiClientProvider).dio);
});

class QrInvitationRepository {
  QrInvitationRepository(this._dio);

  final Dio _dio;

  Future<List<VisitQrCode>> getHistory({String? estado}) async {
    final response = await _dio.get(
      '/invitaciones-qr',
      queryParameters: {
        if (estado != null) 'estado': estado,
      },
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? []) : (raw ?? []);
    return (list as List)
        .map((e) => VisitQrCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VisitQrCode> create({
    required int apartmentId,
    required String visitorName,
    required String documentType,
    required String documentNumber,
    required String validFrom,
    required String validUntil,
  }) async {
    final response = await _dio.post('/invitaciones-qr', data: {
      'apartment_id': apartmentId,
      'visitor_name': visitorName,
      'document_type': documentType,
      'document_number': documentNumber,
      'valid_from': validFrom,
      'valid_until': validUntil,
    });
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return VisitQrCode.fromJson(data);
  }

  Future<void> revoke(int id) async {
    await _dio.delete('/invitaciones-qr/$id');
  }
}
