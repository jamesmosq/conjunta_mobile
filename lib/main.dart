import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive para caché offline
  await Hive.initFlutter();

  // Firebase (FCM)
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: App()));
}
