import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_reset.dart';
import '../data/auth_repository.dart';
import '../models/user_session.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.read(authRepositoryProvider);
    final stored = await repo.getStoredSession();
    if (stored == null) return null;
    return AuthUser(
      id: stored.userId,
      name: stored.name ?? '',
      email: stored.email ?? '',
      role: stored.role,
      tenantId: stored.tenantId,
      apartmentId: stored.apartmentId,
    );
  }

  Future<void> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    // Por si quedó algo cacheado de una sesión anterior en el mismo proceso
    // (logout sin cerrar la app) — se limpia también DESPUÉS de un login
    // exitoso, ya que cualquier pantalla pudo reconstruir su provider entre
    // el logout anterior y este login con el usuario todavía en null.
    resetUserScopedProviders(ref);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
            deviceName: deviceName,
          );
      // Refresh completo con me() para obtener apartment_id
      try {
        final me = await ref.read(authRepositoryProvider).me();
        return me;
      } catch (_) {
        return session.user;
      }
    });

    resetUserScopedProviders(ref);
  }

  Future<void> logout() async {
    try {
      // Timeout defensivo: un `try/finally` no protege contra una llamada
      // que se cuelga sin lanzar (canal de plataforma bloqueado, red caída
      // sin timeout propio, etc.) — sin este límite, el `finally` de abajo
      // nunca se alcanza y el usuario queda atrapado en la pantalla anterior
      // con la sesión aparentando estar activa.
      await ref
          .read(authRepositoryProvider)
          .logout()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignorado a propósito — el logout visual (abajo) es incondicional.
    } finally {
      // El usuario siempre debe salir de la sesión visualmente, incluso si
      // algo imprevisto en el repositorio (red, storage) lanza una excepción
      // o no responde a tiempo.
      state = const AsyncData(null);
      // Sin esto, el siguiente usuario que inicie sesión en el mismo
      // proceso (sin forzar el cierre de la app) puede ver pantallas con
      // datos cacheados de ESTA cuenta — perfil, reservas, paquetes, etc.
      resetUserScopedProviders(ref);
    }
  }

  /// Limpia el estado local sin llamar al backend — para cuando el token
  /// ya se sabe inválido (401 detectado por el interceptor global) y un
  /// POST /auth/logout solo fallaría con el mismo error.
  void forceLogout() {
    state = const AsyncData(null);
    resetUserScopedProviders(ref);
  }

  Future<void> refreshUser() async {
    try {
      final me = await ref.read(authRepositoryProvider).me();
      state = AsyncData(me);
    } catch (_) {}
  }
}
