import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'pusher_client.dart';
import '../../features/announcements/providers/announcements_provider.dart';
import '../../features/pqrs/providers/pqrs_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/porteria/models/access_event.dart';
import '../../features/porteria/providers/live_access_provider.dart';
import '../../features/porteria/providers/porteria_provider.dart';
import '../../features/areas/providers/areas_provider.dart';
import '../../features/maintenance/providers/maintenance_provider.dart';
import '../../features/contractor/providers/contractor_provider.dart';
import '../../features/chat/models/chat_models.dart';
import '../../features/chat/providers/chat_provider.dart';

final reverbServiceProvider = Provider<ReverbService>((ref) {
  return ReverbService(ref);
});

class ReverbService {
  ReverbService(this._ref);

  final Ref _ref;
  PusherWsClient? _client;
  bool _initialized = false;

  Future<void> initialize({
    required String userId,
    required String role,
    required int? tenantId,
  }) async {
    if (_initialized) return;

    final token = await _ref.read(secureStorageProvider).getToken();
    if (token == null) return;

    try {
      _client = PusherWsClient(
        wsUrl: AppConfig.reverbWsUrl,
        authEndpoint: AppConfig.broadcastingAuthUrl,
        bearerToken: token,
        onEvent: _onEvent,
      );

      await _client!.connect();
      _initialized = true;

      if (tenantId != null) {
        // Backend autoriza este canal por user id propio (routes/channels.php:
        // `apto.{userId}` -> `$user->id === $userId`), no por apartamento —
        // antes se suscribía con `apartmentId`, que nunca coincide con el id
        // del usuario, así que la suscripción siempre era rechazada (403) y
        // el copropietario nunca recibía tiempo real en foreground.
        if (role == 'copropietario') {
          await _client!.subscribe('private-apto.$userId');
        }
        if (role == 'portero') {
          await _client!.subscribe('private-porteria.$tenantId');
        }
        if (['administrador', 'auxiliar_contable', 'consejo',
            'revisor_fiscal'].contains(role)) {
          await _client!.subscribe('private-admin.$tenantId');
        }
        if (role == 'contratista') {
          await _client!.subscribe('private-contratista.$userId');
        }
      }
    } catch (_) {
      // Reverb no disponible — la app funciona sin tiempo real
    }
  }

  Future<void> subscribeChatThread(int conversationId) async {
    if (!_initialized) return;
    try {
      await _client!.subscribe('private-chat.$conversationId');
    } catch (_) {}
  }

  Future<void> disconnect() async {
    if (!_initialized) return;
    try {
      await _client?.disconnect();
    } catch (_) {}
    _client = null;
    _initialized = false;
  }

  void _handleChatEvent(
    String channelName,
    String eventName,
    Map<String, dynamic> data,
  ) {
    final convIdStr = channelName.split('.').lastOrNull;
    final convId = int.tryParse(convIdStr ?? '');
    if (convId == null) return;

    switch (eventName) {
      case 'message.sent':
        _ref.invalidate(chatConversationsProvider);
        try {
          _ref
              .read(chatThreadProvider(convId).notifier)
              .receiveMessage(ChatMessage.fromReverbData(data));
        } catch (_) {}
      case 'messages.read':
        _ref.invalidate(chatConversationsProvider);
        final readByUserId = data['read_by_user_id'] as int?;
        if (readByUserId != null) {
          try {
            _ref
                .read(chatThreadProvider(convId).notifier)
                .markAllRead(readByUserId);
          } catch (_) {}
        }
    }
  }

  void _onEvent(
    String channelName,
    String eventName,
    Map<String, dynamic> data,
  ) {
    if (channelName.startsWith('private-chat.')) {
      _handleChatEvent(channelName, eventName, data);
      return;
    }

    switch (eventName) {
      case 'visit.registered':
        _ref.invalidate(visitsProvider);
        try {
          final accessEvent = AccessEvent.fromJson(data);
          _ref.read(liveAccessProvider.notifier).notify(accessEvent);
        } catch (_) {}
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
      case 'access_request.decided':
        // Portero: si es la solicitud que está siguiendo en vivo, actualiza
        // su estado sin esperar a que refresque la lista.
        final id = data['access_request_id'] as int?;
        final status = data['status'] as String?;
        if (id != null && status != null) {
          try {
            _ref.read(activeAccessRequestProvider.notifier).applyDecision(
                  id,
                  status,
                  data['responded_by'] as String?,
                );
          } catch (_) {}
        }
        _ref.invalidate(accessRequestsProvider);
    }
  }
}
