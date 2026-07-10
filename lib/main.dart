import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DateFormat(..., 'es') se usa en la mayoría de pantallas de listas
  // (encuestas, áreas comunes, portería, estado de cuenta, PQRS, etc.).
  // Sin esto, cada una de ellas revienta con LocaleDataException apenas
  // intenta formatear una fecha — en release, sin stacktrace visible,
  // se ve como una pantalla en blanco/gris.
  await initializeDateFormatting('es');

  // Hive para caché offline
  await Hive.initFlutter();

  // Firebase (FCM)
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: App()));
}
