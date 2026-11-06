import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/demo.dart';
import 'core/firebase_bootstrap.dart';

/// `flutter run --dart-define=DEMO=true` force le mode démo.
const _forcerDemo = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  final firebase = _forcerDemo
      ? const FirebaseStatus.demo()
      : await initFirebase();
  if (!firebase.isDemo) {
    runApp(FoodYokfaApp(firebase: firebase));
    return;
  }
  final FirebaseFirestore base;
  try {
    base = await ModeDemo.creerBase();
  } catch (e) {
    // La base de démo ne fonctionne que dans les versions de développement
    // (flutter run, bouton Run d'Android Studio), pas dans un APK release.
    runApp(FoodYokfaApp(firebase: FirebaseStatus.failed(e.toString())));
    return;
  }
  ModeDemo.actif = true;
  runApp(
    FoodYokfaApp(
      firebase: firebase,
      db: base,
      identite: IdentiteDemo(),
      authGerant: AuthGerantDemo(),
      notifications: NotificationsDemo(),
    ),
  );
}
