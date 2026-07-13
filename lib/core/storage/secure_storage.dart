import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyToken = 'sanctum_token';
const _keyUserId = 'user_id';
const _keyUserRole = 'user_role';
const _keyTenantId = 'tenant_id';
const _keyApartmentId = 'apartment_id';
const _keyUserName = 'user_name';
const _keyUserEmail = 'user_email';

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> saveSession({
    required String token,
    required int userId,
    required String role,
    required int? tenantId,
    int? apartmentId,
    String? name,
    String? email,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyUserRole, value: role),
      _storage.write(key: _keyTenantId, value: tenantId?.toString()),
      _storage.write(key: _keyApartmentId, value: apartmentId?.toString()),
      _storage.write(key: _keyUserName, value: name),
      _storage.write(key: _keyUserEmail, value: email),
    ]);
  }

  Future<SessionData?> getSession() async {
    final results = await Future.wait([
      _storage.read(key: _keyToken),
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserRole),
      _storage.read(key: _keyTenantId),
      _storage.read(key: _keyApartmentId),
      _storage.read(key: _keyUserName),
      _storage.read(key: _keyUserEmail),
    ]);
    final token = results[0];
    final userId = results[1];
    final role = results[2];
    if (token == null || userId == null || role == null) return null;
    return SessionData(
      token: token,
      userId: int.parse(userId),
      role: role,
      tenantId: results[3] != null ? int.parse(results[3]!) : null,
      apartmentId: results[4] != null ? int.parse(results[4]!) : null,
      name: results[5],
      email: results[6],
    );
  }

  /// `deleteAll()` en Android (con `encryptedSharedPreferences: true`) tiene un
  /// problema documentado en el propio repo del plugin: en ciertos dispositivos
  /// se queda colgado indefinidamente en el canal de plataforma — no lanza
  /// excepción, simplemente el `await` nunca resuelve. Un `try/catch` alrededor
  /// no sirve de nada contra un hang (solo contra un throw), así que:
  /// 1. Nunca se llama `deleteAll()` — se borra clave por clave, que no tiene
  ///    ese problema reportado.
  /// 2. Cada borrado individual además lleva un timeout corto: si el canal de
  ///    plataforma se cuelga igual por cualquier otra razón, no bloquea el
  ///    logout — la clave puede quedar huérfana en el peor caso, pero el
  ///    usuario nunca se queda atascado en la pantalla anterior.
  Future<void> clearSession() async {
    const keys = [
      _keyToken,
      _keyUserId,
      _keyUserRole,
      _keyTenantId,
      _keyApartmentId,
      _keyUserName,
      _keyUserEmail,
    ];
    await Future.wait(keys.map((key) => _storage
        .delete(key: key)
        .timeout(const Duration(seconds: 3))
        .catchError((_) {})));
  }
}

class SessionData {
  const SessionData({
    required this.token,
    required this.userId,
    required this.role,
    this.tenantId,
    this.apartmentId,
    this.name,
    this.email,
  });
  final String token;
  final int userId;
  final String role;
  final int? tenantId;
  final int? apartmentId;
  final String? name;
  final String? email;
}
