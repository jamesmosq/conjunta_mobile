import 'package:dio/dio.dart';

/// Extrae el mensaje claro que manda el backend (`{"message": "..."}`) de un
/// error de red; si no hay uno, cae al mensaje genérico dado. Evita mostrarle
/// al usuario el `toString()` crudo de un DioException.
String dioErrorMessage(Object e, [String fallback = 'Ocurrió un error. Intenta de nuevo.']) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 403) {
      return 'No tienes permiso para esta acción.';
    }
  }
  return fallback;
}
