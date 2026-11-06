import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Résultat de l'initialisation de Firebase au démarrage.
class FirebaseStatus {
  const FirebaseStatus.ready() : error = null, isDemo = false;
  const FirebaseStatus.failed(this.error) : isDemo = false;

  /// Mode démo : données locales, rien n'est envoyé à Firebase.
  const FirebaseStatus.demo() : error = null, isDemo = true;

  /// Message d'erreur si Firebase n'a pas pu démarrer, sinon `null`.
  final String? error;

  final bool isDemo;

  bool get isReady => error == null;
}

/// Initialise Firebase. Ne fait jamais planter l'application :
/// - projet pas encore configuré (`flutterfire configure` pas lancé) :
///   l'appli démarre en mode démo ;
/// - autre échec : l'erreur est affichée à l'écran.
Future<FirebaseStatus> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return const FirebaseStatus.ready();
  } on UnsupportedError catch (e) {
    debugPrint('Firebase non configuré, mode démo : ${e.message}');
    return const FirebaseStatus.demo();
  } catch (e) {
    debugPrint('Firebase non initialisé : $e');
    return FirebaseStatus.failed(e.toString());
  }
}
