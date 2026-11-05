// Fichier provisoire.
//
// Il sera remplacé par la commande `flutterfire configure` (voir README),
// qui génère les identifiants du projet Firebase pour Android et iOS.
// Tant que ce fichier n'est pas remplacé, l'application démarre sans
// Firebase et affiche un écran d'avertissement.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase n\'est pas encore configuré. '
      'Lancez `flutterfire configure` à la racine du projet.',
    );
  }
}
