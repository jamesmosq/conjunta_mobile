import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/services/reverb_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Escucha cambios de auth para conectar/desconectar servicios
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(authStateProvider, (prev, next) {
        final user = next.value;
        if (user != null && !_servicesInitialized) {
          _servicesInitialized = true;
          _initServices(user);
        } else if (user == null && _servicesInitialized) {
          _servicesInitialized = false;
          _disconnectServices();
        }
      });
      // El backend respondió 401 en algún request: el token ya no sirve.
      // Se limpia el estado de auth para que GoRouter redirija a /login,
      // en vez de dejar al usuario atascado en una pantalla de error.
      ref.listenManual(unauthorizedEventProvider, (prev, next) {
        if (prev != null && next != prev) {
          ref.read(authStateProvider.notifier).forceLogout();
        }
      });
    });
  }

  Future<void> _initServices(dynamic user) async {
    // FCM
    await ref.read(fcmServiceProvider).initialize();

    // Reverb WebSocket
    await ref.read(reverbServiceProvider).initialize(
          userId: user.id.toString(),
          role: user.role,
          tenantId: user.tenantId,
          apartmentId: user.apartmentId,
        );
  }

  Future<void> _disconnectServices() async {
    await ref.read(reverbServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Conjunto Residencial',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'CO'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es'),
      ],
    );
  }
}
