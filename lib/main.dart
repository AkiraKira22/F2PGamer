import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/favorites_service.dart';

Future<void> main() async {
  // Required before any plugin (Firebase) work happens in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase reads its configuration from android/app/google-services.json,
  // so no generated options file is needed for the Android build.
  await Firebase.initializeApp();

  // Load persisted favorites before the UI reads them.
  await FavoritesService.instance.init();

  runApp(const F2PGamerApp());
}
