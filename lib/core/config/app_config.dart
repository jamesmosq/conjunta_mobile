import 'package:flutter/material.dart';

class AppConfig {
  static const String _prodHost = 'https://conjunta-production.up.railway.app';

  static const String baseUrl = '$_prodHost/api/v1';

  /// El endpoint de autorización de canales privados de Reverb lo registra
  /// Laravel en la raíz (`/broadcasting/auth`, igual que resources/js/app.js
  /// para el panel web), NO bajo el prefijo /api/v1 de las demás rutas.
  static const String broadcastingAuthUrl = '$_prodHost/broadcasting/auth';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // Reverb — WebSocket sobre WSS.
  // Cuando se cree el servicio Reverb en Railway, actualiza _reverbHost
  // con el dominio que Railway asigne (ej: conjunta-reverb.up.railway.app).
  static const String _reverbHost = 'conjunta-production.up.railway.app';
  static const String _reverbKey  = 'kfpq4wjevadkvz6yub6k';

  static const String reverbWsUrl =
      'wss://$_reverbHost/app/$_reverbKey'
      '?protocol=7&client=flutter&version=1.0.0&flash=false';

  // NavigatorKey global para mostrar SnackBars desde FCM service
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
