import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';

/// Renderiza automáticamente loading / error / data para AsyncValue.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? st)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          error?.call(e, st) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _friendlyError(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  // El interceptor global ya debería redirigir a /login ante
                  // un 401, pero se deja esta salida manual por si esa
                  // pantalla se construyó antes de que el redirect ocurriera.
                  if (_isSessionExpired(e)) ...[
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, _) => OutlinedButton(
                        onPressed: () =>
                            ref.read(authStateProvider.notifier).logout(),
                        child: const Text('Volver a iniciar sesión'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  bool _isSessionExpired(Object e) {
    final msg = e.toString();
    return msg.contains('401') || msg.contains('Unauthenticated');
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Sin conexión a internet. Verifica tu red.';
    }
    if (_isSessionExpired(e)) {
      return 'Sesión expirada. Por favor inicia sesión de nuevo.';
    }
    if (msg.contains('403')) {
      return 'No tienes permiso para esta acción.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
