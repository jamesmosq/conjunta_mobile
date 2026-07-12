import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      // El usuario siempre debe salir de la sesión visualmente, incluso si
      // algo imprevisto en el repositorio (red, storage) lanza una excepción.
      state = const AsyncData(null);
    }
  }

  /// Limpia el estado local sin llamar al backend — para cuando el token
  /// ya se sabe inválido (401 detectado por el interceptor global) y un
  /// POST /auth/logout solo fallaría con el mismo error.
  void forceLogout() {
    state = const AsyncData(null);
  }

  Future<void> refreshUser() async {
    try {
      final me = await ref.read(authRepositoryProvider).me();
      state = AsyncData(me);
    } catch (_) {}
  }
}
