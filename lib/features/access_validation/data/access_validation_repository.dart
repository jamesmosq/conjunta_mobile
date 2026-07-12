import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/qr_preview.dart';

final accessValidationRepositoryProvider =
    Provider<AccessValidationRepository>((ref) {
  return AccessValidationRepository(ref.read(apiClientProvider).dio);
});

class AccessValidationRepository {
  AccessValidationRepository(this._dio);

  final Dio _dio;

  Future<QrPreview> previewByUuid(String uuid, String token) async {
    final response = await _dio.get(
      '/qr/$uuid',
      queryParameters: {'token': token},
    );
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return QrPreview.fromJson(data);
  }

  Future<void> confirmByUuid(String uuid, String token) async {
    await _dio.post('/qr/$uuid/usar', data: {'token': token});
  }

  Future<QrPreview> previewByCode(String code) async {
    final response = await _dio.get('/qr/code/$code');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return QrPreview.fromJson(data);
  }

  Future<void> confirmByCode(String code) async {
    await _dio.post('/qr/code/$code/usar');
  }

  /// Registra la salida del visitante repitiendo el mismo código corto
  /// usado al ingresar — mismo patrón que el panel web (QrScanner modo
  /// "salida"). Retorna el nombre del visitante para la confirmación.
  Future<String> exitByCode(String code) async {
    final response = await _dio.post('/visits/exit-by-code/$code');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return data['visitor_name'] as String? ?? 'Visitante';
  }
}
