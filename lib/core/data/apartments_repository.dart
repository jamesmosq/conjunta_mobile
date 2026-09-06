import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/apartment_lookup.dart';
import '../models/apartment_residents.dart';
import '../network/api_client.dart';

final apartmentsRepositoryProvider = Provider<ApartmentsRepository>((ref) {
  return ApartmentsRepository(ref.read(apiClientProvider).dio);
});

class ApartmentsRepository {
  ApartmentsRepository(this._dio);

  final Dio _dio;

  Future<List<ApartmentLookup>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get(
      '/apartments',
      queryParameters: {'search': query.trim()},
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => ApartmentLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Directorio de residentes (QA #35) — mismo endpoint que [search], pero
  /// conserva los nombres de residentes de la respuesta en vez de
  /// descartarlos. Sin query devuelve el listado completo (paginado por el
  /// backend, 50 por página) para que portero pueda ojear el conjunto.
  Future<List<ApartmentResidents>> searchDirectory(String query) async {
    final response = await _dio.get(
      '/apartments',
      queryParameters: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
      },
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    return (list as List)
        .map((e) => ApartmentResidents.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
