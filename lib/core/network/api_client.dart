import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Se incrementa cada vez que el backend responde 401. `app.dart` escucha
/// este provider (fuera de la capa de red, para evitar un import circular
/// con el provider de auth) y fuerza el logout + redirect a /login.
final unauthorizedEventProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.read(secureStorageProvider),
    onUnauthorized: () => ref.read(unauthorizedEventProvider.notifier).state++,
  );
});

class ApiClient {
  ApiClient(this._storage, {required this.onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_storage, onUnauthorized));
  }

  final SecureStorageService _storage;
  final void Function() onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._onUnauthorized);
  final SecureStorageService _storage;
  final void Function() _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 → el token ya no es válido en el backend (expiró o fue revocado).
    // Se limpia localmente y se notifica para que la app redirija a /login
    // en vez de dejar cada pantalla mostrando su propio error sin salida.
    if (err.response?.statusCode == 401) {
      await _storage.clearSession();
      _onUnauthorized();
    }
    handler.next(err);
  }
}
