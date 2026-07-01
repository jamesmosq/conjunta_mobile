import 'package:flutter/material.dart';

class AppConfig {
  // Android emulator → 10.0.2.2 es el localhost del host
  // php artisan serve --host=0.0.0.0 --port=8080 (corre en paralelo a Herd)
  // Dispositivo físico → reemplazar 10.0.2.2 por la IP local (ej: 192.168.1.x)
  static const String _devHost = 'http://10.0.2.2:8080';

  static const String baseUrl = '$_devHost/api/v1';

  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 30000;

  // Reverb — WebSocket (protocolo Pusher compatible)
  static const String reverbHost = '10.0.2.2';
  static const int reverbPort = 8080;
  static const String reverbKey = 'kfpq4wjevadkvz6yub6k'; // REVERB_APP_KEY del .env
  static const String reverbCluster = 'mt1'; // dummy — Reverb no usa clusters

  // NavigatorKey global para mostrar SnackBars desde FCM service
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
