import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/maintenance/models/maintenance_request.dart';
import '../../features/maintenance/providers/maintenance_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';

// Top-level — fuera de cualquier clase (requisito de FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Solo log — la navegación ocurre cuando el usuario toca la notificación
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _registerToken();
    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App terminada: el usuario tocó la notificación para abrir la app
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Diferimos hasta que el router esté montado
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleTap(initial),
      );
    }
  }

  // ─── Token ────────────────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (_) {}
  }

  Future<void> _saveToken(String token) async {
    try {
      await _ref.read(authRepositoryProvider).updateFcmToken(token);
    } catch (_) {}
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      _ref.invalidate(notificationsProvider);
    } catch (_) {}

    final context = AppConfig.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final title = message.notification?.title ?? 'Nueva notificación';
    final body = message.notification?.body;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (body != null && body.isNotEmpty)
              Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _navigateFromPayload(
            _ref.read(routerProvider),
            message.data,
          ),
        ),
      ),
    );
  }

  void _handleTap(RemoteMessage message) {
    _navigateFromPayload(_ref.read(routerProvider), message.data);
  }

  // ─── Navegación ───────────────────────────────────────────────────────────

  void _navigateFromPayload(GoRouter router, Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      // Cuenta / Cobros
      case 'charge_added':
      case 'charge_updated':
        router.push('/account');

      // Portería — acceso y paquetes
      case 'visit_registered':
        router.push('/porteria');
      case 'pre_authorization_created':
        router.push('/visits/pre-auth');
      case 'package_arrived':
        router.push('/porteria');

      // Áreas comunes — reservas
      case 'booking_approved':
      case 'booking_rejected':
        final areaId = _parseInt(data['area_id']);
        if (areaId != null) {
          router.push('/areas/$areaId');
        } else {
          router.push('/areas');
        }

      // Comunicados
      case 'announcement_created':
      case 'announcement_updated':
        router.push('/announcements');

      // PQRS
      case 'pqrs_responded':
      case 'pqrs_status_changed':
        router.push('/pqrs');

      // Reportes de daños — intenta deep-link directo al reporte
      case 'damage_report.status_updated':
        _navigateToDamageReport(router, data);

      // Contratista — órdenes de trabajo
      case 'work_order_assigned':
      case 'work_order_updated':
        router.push('/contractor/orders');

      // Asamblea (pantalla aún no implementada en mobile)
      case 'assembly_convoked':
        router.push('/home');

      default:
        router.push('/notifications');
    }
  }

  void _navigateToDamageReport(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final reportId = _parseInt(data['damage_report_id']);
    if (reportId != null) {
      final cached = _ref.read(maintenanceRequestsProvider).value;
      final request = cached?.where((r) => r.id == reportId).firstOrNull;
      if (request != null) {
        router.push('/maintenance/detail', extra: request);
        return;
      }
    }
    router.push('/maintenance');
  }

  // ─── Utilidades ───────────────────────────────────────────────────────────

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Ruta a la que debe navegar una [UserNotification] de la bandeja.
  /// Devuelve [null] si el tipo no tiene destino específico más allá de `/notifications`.
  static (String route, MaintenanceRequest? extra) resolveRoute(
    String? type,
    Map<String, dynamic> data, {
    List<MaintenanceRequest>? cachedRequests,
  }) {
    switch (type) {
      case 'charge_added':
      case 'charge_updated':
        return ('/account', null);
      case 'visit_registered':
        return ('/porteria', null);
      case 'pre_authorization_created':
        return ('/visits/pre-auth', null);
      case 'package_arrived':
        return ('/porteria', null);
      case 'booking_approved':
      case 'booking_rejected':
        final areaId = _parseInt(data['area_id']);
        return (areaId != null ? '/areas/$areaId' : '/areas', null);
      case 'announcement_created':
      case 'announcement_updated':
        return ('/announcements', null);
      case 'pqrs_responded':
      case 'pqrs_status_changed':
        return ('/pqrs', null);
      case 'damage_report.status_updated':
        final reportId = _parseInt(data['damage_report_id']);
        if (reportId != null) {
          final req =
              cachedRequests?.where((r) => r.id == reportId).firstOrNull;
          if (req != null) return ('/maintenance/detail', req);
        }
        return ('/maintenance', null);
      case 'work_order_assigned':
      case 'work_order_updated':
        return ('/contractor/orders', null);
      case 'assembly_convoked':
        return ('/home', null);
      default:
        return ('/notifications', null);
    }
  }
}
