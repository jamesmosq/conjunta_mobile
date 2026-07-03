import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef PusherEventHandler = void Function(
  String channelName,
  String eventName,
  Map<String, dynamic> data,
);

/// Cliente mínimo del protocolo Pusher sobre WebSocket puro.
/// Compatible con Laravel Reverb sin depender de pusher_channels_flutter,
/// que no soporta host personalizado en su API Flutter.
class PusherWsClient {
  PusherWsClient({
    required this.wsUrl,
    required this.authEndpoint,
    required this.bearerToken,
    required this.onEvent,
  });

  final String wsUrl;
  final String authEndpoint;
  final String bearerToken;
  final PusherEventHandler onEvent;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  String? _socketId;
  bool _connected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final _subscriptions = <String>{};

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> subscribe(String channelName) async {
    _subscriptions.add(channelName);
    if (_connected) await _doSubscribe(channelName);
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    _socketId = null;
    _subscriptions.clear();
  }

  // ── internal ──────────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final event = msg['event'] as String?;
      final channel = msg['channel'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          final inner = jsonDecode(msg['data'] as String) as Map<String, dynamic>;
          _socketId = inner['socket_id'] as String?;
          _connected = true;
          _startPing();
          for (final ch in List<String>.from(_subscriptions)) {
            _doSubscribe(ch);
          }

        case 'pusher:pong':
        case 'pusher_internal:subscription_succeeded':
          break;

        default:
          if (event != null &&
              channel != null &&
              !event.startsWith('pusher')) {
            onEvent(channel, event, _parseData(msg['data']));
          }
      }
    } catch (_) {}
  }

  Map<String, dynamic> _parseData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  Future<void> _doSubscribe(String channelName) async {
    if (_channel == null || _socketId == null) return;

    String? auth;
    if (channelName.startsWith('private-') ||
        channelName.startsWith('presence-')) {
      auth = await _authenticate(channelName);
      if (auth == null) return;
    }

    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
        if (auth != null) 'auth': auth,
      },
    });
  }

  Future<String?> _authenticate(String channelName) async {
    try {
      final resp = await http.post(
        Uri.parse(authEndpoint),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'channel_name': channelName,
          'socket_id': _socketId!,
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return body['auth'] as String?;
      }
    } catch (_) {}
    return null;
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  void _scheduleReconnect() {
    _connected = false;
    _socketId = null;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      connect,
    );
  }
}
