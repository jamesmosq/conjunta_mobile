import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../../features/announcements/providers/announcements_provider.dart';
import '../../features/pqrs/providers/pqrs_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/porteria/models/access_event.dart';
import '../../features/porteria/providers/live_access_provider.dart';
import '../../features/porteria/providers/porteria_provider.dart';
import '../../features/areas/providers/areas_provider.dart';
import '../../features/maintenance/providers/maintenance_provider.dart';
import '../../features/contractor/providers/contractor_provider.dart';

final reverbServiceProvider = Provider<ReverbService>((ref) {
  return ReverbService(ref);
});

class ReverbService {
  ReverbService(this._ref);

  final Ref _ref;
  final _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;

  Future<void> initialize({
    required String userId,
    required String role,
    required int? tenantId,
    required int? apartmentId,
  }) async {
    if (_initialized) return;

    final token = await _ref.read(secureStorageProvider).getToken();
    if (token == null) return;

    try {
      await _pusher.init(
        apiKey: AppConfig.reverbKey,
        cluster: AppConfig.reverbCluster,
        useTLS: false,
        onEvent: _onEvent,
        onConnectionStateChange: (curr, prev) {},
        onError: (message, code, e) {},
        // Autenticador para canales privados — llama al endpoint de broadcasting
        onAuthorizer: (channelName, socketId, options) async {
          try {
            final response = await http.post(
              Uri.parse('${AppConfig.baseUrl}/broadcasting/auth'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
              },
              body: {
                'channel_name': channelName,
                'socket_id': socketId,
              },
            );
            if (response.statusCode == 200) {
              return jsonDecode(response.body);
            }
          } catch (_) {}
          return {};
        },
      );

      await _pusher.connect();
      _initialized = true;

      if (tenantId != null) {
        if (role == 'copropietario' && apartmentId != null) {
          await _subscribe('private-apto.$apartmentId');
        }
        if (role == 'portero') {
          await _subscribe('private-porteria.$tenantId');
        }
        if (['administrador', 'auxiliar_contable', 'consejo',
            'revisor_fiscal'].contains(role)) {
          await _subscribe('private-admin.$tenantId');
        }
        if (role == 'contratista') {
          await _subscribe('private-contratista.$userId');
        }
      }
    } catch (_) {
      // Reverb no disponible — la app funciona sin tiempo real
    }
  }

  Future<void> disconnect() async {
    if (!_initialized) return;
    try {
      await _pusher.disconnect();
    } catch (_) {}
    _initialized = false;
  }

  Future<void> _subscribe(String channelName) async {
    await _pusher.subscribe(channelName: channelName, onEvent: _onEvent);
  }

  void _onEvent(PusherEvent event) {
    switch (event.eventName) {
      case 'visit.registered':
        _ref.invalidate(visitsProvider);
        if (event.data != null) {
          try {
            final data = jsonDecode(event.data!) as Map<String, dynamic>;
            final accessEvent = AccessEvent.fromJson(data);
            _ref.read(liveAccessProvider.notifier).notify(accessEvent);
          } catch (_) {}
        }
      case 'package.arrived':
        _ref.invalidate(packagesProvider);
      case 'charge.added':
      case 'charge.updated':
      case 'notification.created':
        _ref.invalidate(notificationsProvider);
      case 'announcement.created':
      case 'announcement.updated':
        _ref.read(announcementsProvider.notifier).refresh();
        _ref.invalidate(notificationsProvider);
      case 'pqrs.responded':
      case 'pqrs.status_changed':
        _ref.read(pqrsProvider.notifier).refresh();
      case 'booking.status_changed':
        _ref.invalidate(myBookingsProvider);
      case 'damage_report.status_changed':
        _ref.invalidate(maintenanceRequestsProvider);
      case 'work_order.assigned':
      case 'work_order.updated':
        _ref.invalidate(activeWorkOrdersProvider);
        _ref.invalidate(notificationsProvider);
    }
  }
}
