import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Résultat de l'initialisation de Firebase au démarrage.
class FirebaseStatus {
  const FirebaseStatus.ready() : error = null;
  const FirebaseStatus.failed(this.error);

  /// Message d'erreur si Firebase n'a pas pu démarrer, sinon `null`.
  final String? error;

  bool get isReady => error == null;
}

/// Initialise Firebase. Ne fait jamais planter l'application :
/// en cas d'échec (projet pas encore configuré, par exemple),
/// renvoie l'erreur pour qu'elle soit affichée à l'écran.
Future<FirebaseStatus> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return const FirebaseStatus.ready();
  } catch (e) {
    debugPrint('Firebase non initialisé : $e');
    return FirebaseStatus.failed(e.toString());
  }
}
